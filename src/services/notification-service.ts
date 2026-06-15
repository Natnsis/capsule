type NotificationsModule = typeof import("expo-notifications");

let Notifications: NotificationsModule | null = null;
let initAttempted = false;
let isExpoGo = false;

try {
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

export const NotificationService = {
  async requestPermission(): Promise<boolean> {
    const mod = await getNotifications();
    if (!mod) return false;

    const { status: existing } = await mod.getPermissionsAsync();
    if (existing === "granted") return true;
    const { status } = await mod.requestPermissionsAsync();
    return status === "granted";
  },

  async scheduleCapsuleReminder(
    capsuleId: string,
    title: string,
    openAt: number
  ): Promise<string | null> {
    const mod = await getNotifications();
    if (!mod) return null;

    try {
      const trigger = new Date(openAt);
      if (trigger.getTime() <= Date.now()) return null;

      const id = await mod.scheduleNotificationAsync({
        content: {
          title: "A TimeCapsule is ready to open!",
          body: `"${title}" — Your message from the past has arrived.`,
          data: { capsuleId },
          sound: true,
        },
        trigger: {
          date: trigger,
          type: mod.SchedulableTriggerInputTypes.DATE,
        },
      });

      return id;
    } catch {
      return null;
    }
  },

  async cancelReminder(notificationId: string): Promise<void> {
    const mod = await getNotifications();
    if (!mod) return;
    try {
      await mod.cancelScheduledNotificationAsync(notificationId);
    } catch {}
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
};
