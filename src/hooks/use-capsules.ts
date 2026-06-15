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

      const notificationId = await NotificationService.scheduleCapsuleReminder(
        capsule.id,
        capsule.title,
        capsule.openAt
      );

      if (notificationId) {
        await CapsuleRepository.setNotificationId(capsule.id, notificationId);
      }

      return capsule;
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: CAPSULES_KEY });
      queryClient.invalidateQueries({ queryKey: STATS_KEY });
    },
  });
}

export function useOpenCapsule() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: async (id: string) => {
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
      if (capsule?.notificationId) {
        await NotificationService.cancelReminder(capsule.notificationId);
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
