type NotificationsModule = typeof import("expo-notifications");

let Notifications: NotificationsModule | null = null;
let initAttempted = false;
let isExpoGo = false;

try {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  const Constants = require("expo-constants");
  const c = Constants.default ?? Constants;
  isExpoGo = c.appOwnership === "expo";
} catch {}

async function getNotifications(): Promise<NotificationsModule | null> {
  if (initAttempted) return Notifications;
  initAttempted = true;

  if (isExpoGo) return null;

  try {
    const mod = await import("expo-notifications");

    mod.setNotificationHandler({
      handleNotification: async () => ({
        shouldShowAlert: true,
        shouldPlaySound: true,
        shouldSetBadge: false,
        shouldShowBanner: true,
        shouldShowList: true,
      }),
    });

    Notifications = mod;
    return mod;
  } catch {
    return null;
  }
}

// Hours after openAt at which follow-up reminders fire: every 6h for the
// first two days, then tapering off daily up to two weeks. Capped so a
// handful of sealed capsules never come close to iOS's 64-pending-local-
// notification limit; reconcileReminders() tops up further out if the app
// is reopened after this batch is exhausted and the capsule is still unopened.
const FOLLOW_UP_OFFSETS_HOURS = [
  0, 6, 12, 18, 24, 30, 36, 42, 48, 72, 96, 120, 168, 240, 336,
];

function reminderCopy(hoursAfterOpen: number, title: string) {
  if (hoursAfterOpen === 0) {
    return {
      title: "A TimeCapsule is ready to open!",
      body: `"${title}" — your message from the past has arrived.`,
    };
  }
  return {
    title: "Your TimeCapsule is still waiting",
    body: `"${title}" is ready to open. Tap to read it.`,
  };
}

export const NotificationService = {
  async checkPermission(): Promise<boolean> {
    const mod = await getNotifications();
    if (!mod) return false;
    const { status } = await mod.getPermissionsAsync();
    return status === "granted";
  },

  async requestPermission(): Promise<boolean> {
    const mod = await getNotifications();
    if (!mod) return false;

    const { status: existing } = await mod.getPermissionsAsync();
    if (existing === "granted") return true;
    const { status } = await mod.requestPermissionsAsync();
    return status === "granted";
  },

  // Schedules the "ready to open" notification plus a tapering batch of
  // follow-up nudges so the capsule keeps notifying until the user opens it.
  async scheduleCapsuleReminders(
    capsuleId: string,
    title: string,
    openAt: number
  ): Promise<string[]> {
    const mod = await getNotifications();
    if (!mod) return [];

    const ids: string[] = [];
    for (const hours of FOLLOW_UP_OFFSETS_HOURS) {
      const triggerDate = new Date(openAt + hours * 60 * 60 * 1000);
      if (triggerDate.getTime() <= Date.now()) continue;

      try {
        const id = await mod.scheduleNotificationAsync({
          content: {
            ...reminderCopy(hours, title),
            data: { capsuleId },
            sound: true,
          },
          trigger: {
            date: triggerDate,
            type: mod.SchedulableTriggerInputTypes.DATE,
          },
        });
        ids.push(id);
      } catch {}
    }
    return ids;
  },

  // Queues one more nudge `hoursFromNow` out. Used to keep a ready-but-
  // unopened capsule notifying beyond the initial scheduled batch.
  async scheduleTopUpReminder(
    capsuleId: string,
    title: string,
    hoursFromNow = 24
  ): Promise<string | null> {
    const mod = await getNotifications();
    if (!mod) return null;

    try {
      const triggerDate = new Date(Date.now() + hoursFromNow * 60 * 60 * 1000);
      const id = await mod.scheduleNotificationAsync({
        content: {
          ...reminderCopy(1, title),
          data: { capsuleId },
          sound: true,
        },
        trigger: {
          date: triggerDate,
          type: mod.SchedulableTriggerInputTypes.DATE,
        },
      });
      return id;
    } catch {
      return null;
    }
  },

  // Capsule ids that currently have at least one pending scheduled reminder.
  async getPendingCapsuleIds(): Promise<Set<string>> {
    const mod = await getNotifications();
    if (!mod) return new Set();

    try {
      const scheduled = await mod.getAllScheduledNotificationsAsync();
      const ids = scheduled
        .map((n) => n.content.data?.capsuleId as string | undefined)
        .filter((id): id is string => !!id);
      return new Set(ids);
    } catch {
      return new Set();
    }
  },

  async cancelReminders(notificationIds: string[]): Promise<void> {
    const mod = await getNotifications();
    if (!mod) return;
    for (const id of notificationIds) {
      try {
        await mod.cancelScheduledNotificationAsync(id);
      } catch {}
    }
  },

  async cancelAll(): Promise<void> {
    const mod = await getNotifications();
    if (!mod) return;
    try {
      await mod.cancelAllScheduledNotificationsAsync();
    } catch {}
  },

  async addResponseListener(callback: (capsuleId: string) => void) {
    const mod = await getNotifications();
    if (!mod) return { remove: () => {} };

    try {
      const subscription = mod.addNotificationResponseReceivedListener(
        (response: any) => {
          const capsuleId = response.notification.request.content.data
            ?.capsuleId as string;
          if (capsuleId) callback(capsuleId);
        }
      );
      return subscription;
    } catch {
      return { remove: () => {} };
    }
  },

  // For cold starts: the app can be launched directly from a notification
  // tap, in which case the response listener above never fires.
  async getInitialCapsuleId(): Promise<string | null> {
    const mod = await getNotifications();
    if (!mod) return null;
    try {
      const response = await mod.getLastNotificationResponseAsync();
      const capsuleId = response?.notification.request.content.data
        ?.capsuleId as string | undefined;
      return capsuleId ?? null;
    } catch {
      return null;
    }
  },
};
