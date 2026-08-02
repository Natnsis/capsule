import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { CapsuleRepository } from "@/db/repositories/capsule-repository";
import { NotificationService } from "@/services/notification-service";
import type { Capsule, CreateCapsuleInput } from "@/types/capsule";

const CAPSULES_KEY = ["capsules"];
const CAPSULE_KEY = (id: string) => ["capsule", id];
const STATS_KEY = ["capsule-stats"];

export function useCapsules() {
  return useQuery({
    queryKey: CAPSULES_KEY,
    queryFn: CapsuleRepository.getAll,
  });
}

export function useSealedCapsules() {
  return useQuery({
    queryKey: [...CAPSULES_KEY, "sealed"],
    queryFn: () => CapsuleRepository.getByStatus("sealed"),
  });
}

export function useReadyCapsules() {
  return useQuery({
    queryKey: [...CAPSULES_KEY, "ready"],
    queryFn: () => CapsuleRepository.getByStatus("ready"),
  });
}

export function useOpenedCapsules() {
  return useQuery({
    queryKey: [...CAPSULES_KEY, "opened"],
    queryFn: () => CapsuleRepository.getByStatus("opened"),
  });
}

export function useCapsule(id: string) {
  return useQuery({
    queryKey: CAPSULE_KEY(id),
    queryFn: () => CapsuleRepository.getById(id),
    enabled: !!id,
  });
}

export function useCapsuleStats() {
  return useQuery({
    queryKey: STATS_KEY,
    queryFn: CapsuleRepository.getStats,
  });
}

export function useSearchCapsules() {
  const queryClient = useQueryClient();

  return (query: string) =>
    queryClient.fetchQuery({
      queryKey: [...CAPSULES_KEY, "search", query],
      queryFn: () => CapsuleRepository.search(query),
    });
}

export function useCreateCapsule() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (input: CreateCapsuleInput): Promise<Capsule> => {
      const capsule = await CapsuleRepository.create(input);

      // Drafts aren't locked yet, so there's nothing to count down to —
      // reminders get scheduled when the draft is actually sealed.
      if (capsule.status === "draft") return capsule;

      const notificationIds = await NotificationService.scheduleCapsuleReminders(
        capsule.id,
        capsule.title,
        capsule.openAt
      );

      if (notificationIds.length > 0) {
        await CapsuleRepository.setNotificationIds(capsule.id, notificationIds);
      }

      return { ...capsule, notificationIds };
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: CAPSULES_KEY });
      queryClient.invalidateQueries({ queryKey: STATS_KEY });
    },
  });
}

export function useSealDraft() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string): Promise<Capsule | null> => {
      const capsule = await CapsuleRepository.sealDraft(id);
      if (!capsule) return null;

      const notificationIds = await NotificationService.scheduleCapsuleReminders(
        capsule.id,
        capsule.title,
        capsule.openAt
      );

      if (notificationIds.length > 0) {
        await CapsuleRepository.setNotificationIds(capsule.id, notificationIds);
      }

      return { ...capsule, notificationIds };
    },
    onSuccess: (_data: Capsule | null, id: string) => {
      queryClient.invalidateQueries({ queryKey: CAPSULES_KEY });
      queryClient.invalidateQueries({ queryKey: CAPSULE_KEY(id) });
      queryClient.invalidateQueries({ queryKey: STATS_KEY });
    },
  });
}

export function useOpenCapsule() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const capsule = await CapsuleRepository.getById(id);
      if (capsule && capsule.notificationIds.length > 0) {
        await NotificationService.cancelReminders(capsule.notificationIds);
      }
      await CapsuleRepository.updateStatus(id, "opened");
    },
    onSuccess: (_data: void, id: string) => {
      queryClient.invalidateQueries({ queryKey: CAPSULES_KEY });
      queryClient.invalidateQueries({ queryKey: CAPSULE_KEY(id) });
      queryClient.invalidateQueries({ queryKey: STATS_KEY });
    },
  });
}

export function useDeleteCapsule() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
      const capsule = await CapsuleRepository.getById(id);
      if (capsule && capsule.notificationIds.length > 0) {
        await NotificationService.cancelReminders(capsule.notificationIds);
      }
      await CapsuleRepository.delete(id);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: CAPSULES_KEY });
      queryClient.invalidateQueries({ queryKey: STATS_KEY });
    },
  });
}

export function useCheckReadyCapsules() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: CapsuleRepository.checkAndUpdateReadyCapsules,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: CAPSULES_KEY });
      queryClient.invalidateQueries({ queryKey: STATS_KEY });
    },
  });
}

// Keeps ready-but-unopened capsules notifying beyond their initial scheduled
// batch. Call on app boot/foreground: for any ready capsule with no pending
// reminder left, queue one more nudge so it keeps interrupting the user
// until they actually open it.
export async function reconcileCapsuleReminders(): Promise<void> {
  const readyCapsules = await CapsuleRepository.getByStatus("ready");
  if (readyCapsules.length === 0) return;

  const pendingCapsuleIds = await NotificationService.getPendingCapsuleIds();

  for (const capsule of readyCapsules) {
    if (pendingCapsuleIds.has(capsule.id)) continue;
    const newId = await NotificationService.scheduleTopUpReminder(
      capsule.id,
      capsule.title
    );
    if (newId) {
      await CapsuleRepository.addNotificationIds(capsule.id, [newId]);
    }
  }
}
