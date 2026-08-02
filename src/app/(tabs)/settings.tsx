import { useState, useEffect } from "react";
import {
  View,
  Text,
  ScrollView,
  TouchableOpacity,
  Switch,
  TextInput,
} from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import {
  Moon,
  Bell,
  Trash2,
  ChevronRight,
  PenLine,
  Fingerprint,
} from "lucide-react-native";

import { useThemeStore } from "@/stores/theme-store";
import { useBiometricStore } from "@/stores/biometric-store";
import { useProfileStore } from "@/stores/profile-store";
import { useCapsuleStats } from "@/hooks/use-capsules";
import { NotificationService } from "@/services/notification-service";
import { BiometricService } from "@/services/biometric-service";
import { CapsuleRepository } from "@/db/repositories/capsule-repository";
import { Toast } from "@/components/shared/toast";
import { Dialog } from "@/components/shared/dialog";

export default function SettingsScreen() {
  const insets = useSafeAreaInsets();
  const mode = useThemeStore((s) => s.mode);
  const setDark = useThemeStore((s) => s.setDark);
  const biometricEnabled = useBiometricStore((s) => s.enabled);
  const setBiometricEnabled = useBiometricStore((s) => s.setEnabled);
  const { name, setName } = useProfileStore();
  const { data: stats } = useCapsuleStats();

  const [notificationsEnabled, setNotificationsEnabled] = useState(false);
  const [editingName, setEditingName] = useState(false);
  const [nameInput, setNameInput] = useState(name);
  const [toast, setToast] = useState<{
    message: string;
    variant: "success" | "error" | "info";
  } | null>(null);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);

  // Sync switch with actual OS permission state on mount
  useEffect(() => {
    NotificationService.checkPermission().then(setNotificationsEnabled);
  }, []);

  const handleSaveName = () => {
    const trimmed = nameInput.trim();
    if (trimmed) {
      setName(trimmed);
      setEditingName(false);
      setToast({ message: "Name saved", variant: "success" });
    }
  };

  const handleDeleteAll = async () => {
    setShowDeleteDialog(false);
    const capsules = await CapsuleRepository.getAll();
    for (const c of capsules) {
      if (c.notificationIds.length > 0) {
        await NotificationService.cancelReminders(c.notificationIds);
      }
      await CapsuleRepository.delete(c.id);
    }
    setToast({ message: "All capsules deleted", variant: "success" });
  };

  const handleToggleBiometric = async (val: boolean) => {
    if (val) {
      const available = await BiometricService.isAvailable();
      if (!available) {
        setToast({ message: "Biometrics not available on this device", variant: "error" });
        return;
      }
      const ok = await BiometricService.authenticate();
      if (!ok) {
        setToast({ message: "Biometric setup cancelled", variant: "error" });
        return;
      }
    }
    setBiometricEnabled(val);
  };

  const statCards = [
    { label: "Total", value: stats?.total ?? 0 },
    { label: "Sealed", value: stats?.sealed ?? 0 },
    { label: "Ready", value: stats?.ready ?? 0 },
    { label: "Opened", value: stats?.opened ?? 0 },
  ];

  return (
    <>
      <Toast
        message={toast?.message ?? ""}
        variant={toast?.variant ?? "info"}
        visible={!!toast}
        onHide={() => setToast(null)}
      />

      <Dialog
        visible={showDeleteDialog}
        title="Delete All Data"
        message="This will permanently delete all your capsules. This action cannot be undone."
        onClose={() => setShowDeleteDialog(false)}
        actions={[
          { label: "Cancel", variant: "cancel", onPress: () => setShowDeleteDialog(false) },
          { label: "Delete All", variant: "destructive", onPress: handleDeleteAll },
        ]}
      />

      {/* Fixed header */}
      <View className="bg-[#EEF0F3] dark:bg-[#181B21] px-4" style={{ paddingTop: insets.top + 16, paddingBottom: 8 }}>
        <Text className="font-heading text-3xl font-bold text-[#181B21] dark:text-[#EEF0F3]">
          Settings
        </Text>
        <Text className="font-sans text-base text-[#5A6072]">
          Manage your preferences and data
        </Text>
      </View>

      {/* Scrollable content */}
      <ScrollView
        className="flex-1 px-4 bg-[#EEF0F3] dark:bg-[#181B21]"
        contentContainerStyle={{ paddingBottom: 120 }}
      >
        {/* Name card */}
        <View className="bg-[#EEF0F3] dark:bg-[#1C2027] rounded-2xl p-5 mb-6 border border-[#C9CFD8]/50">
          <View className="flex-row items-center gap-4">
            <View className="w-14 h-14 rounded-full bg-sage items-center justify-center">
              <Text className="font-heading text-2xl font-bold text-[#EEF0F3]">
                {(name || "G").charAt(0).toUpperCase()}
              </Text>
            </View>
            <View className="flex-1">
              {editingName ? (
                <View className="flex-row items-center gap-2">
                  <TextInput
                    className="flex-1 bg-[#E8EAEE] dark:bg-[#353C48] rounded-xl px-3 py-2 font-sans text-[#181B21] dark:text-[#EEF0F3] text-base"
                    value={nameInput}
                    onChangeText={setNameInput}
                    autoFocus
                    placeholder="Your name"
                    placeholderTextColor="#5A6072"
                  />
                  <TouchableOpacity
                    onPress={handleSaveName}
                    className="bg-sage rounded-xl px-4 py-2"
                  >
                    <Text className="font-sans text-sm font-semibold text-[#EEF0F3]">Save</Text>
                  </TouchableOpacity>
                </View>
              ) : (
                <>
                  <Text className="font-heading text-lg font-semibold text-[#181B21] dark:text-[#EEF0F3]">
                    {name}
                  </Text>
                  <TouchableOpacity
                    onPress={() => { setNameInput(name); setEditingName(true); }}
                    className="flex-row items-center gap-1 mt-0.5"
                  >
                    <PenLine size={12} color="#3B608F" />
                    <Text className="font-sans text-xs text-sage">Edit name</Text>
                  </TouchableOpacity>
                </>
              )}
            </View>
          </View>
        </View>

        {/* Stats grid */}
        {stats && (
          <View className="flex-row flex-wrap gap-3 mb-6">
            {statCards.map((card) => (
              <View
                key={card.label}
                className="bg-[#E8EAEE] dark:bg-[#353C48] rounded-2xl p-4 items-center"
                style={{ width: "47%" }}
              >
                <Text className="font-heading text-3xl font-bold text-[#181B21] dark:text-[#EEF0F3] mb-1">
                  {card.value}
                </Text>
                <Text className="font-sans text-xs text-[#5A6072]">{card.label}</Text>
              </View>
            ))}
          </View>
        )}

        {/* Dark mode */}
        <View className="mb-6">
          <Text className="font-heading text-sm font-semibold text-[#5A6072] uppercase tracking-wider mb-3 px-1">
            Appearance
          </Text>
          <View className="bg-[#EEF0F3] dark:bg-[#1C2027] rounded-2xl overflow-hidden border border-[#C9CFD8]/50">
            <View className="flex-row items-center px-4 py-4">
              <Moon size={20} color="#5A6072" />
              <Text className="flex-1 font-sans text-base ml-3 text-[#181B21] dark:text-[#EEF0F3]">
                Dark Mode
              </Text>
              <Switch
                value={mode === "dark"}
                onValueChange={setDark}
                trackColor={{ false: "#C9CFD8", true: "#3B608F" }}
                thumbColor="#EEF0F3"
              />
            </View>
          </View>
        </View>

        {/* Notifications */}
        <View className="mb-6">
          <Text className="font-heading text-sm font-semibold text-[#5A6072] uppercase tracking-wider mb-3 px-1">
            Notifications
          </Text>
          <View className="bg-[#EEF0F3] dark:bg-[#1C2027] rounded-2xl overflow-hidden border border-[#C9CFD8]/50">
            <View className="flex-row items-center px-4 py-4">
              <Bell size={20} color="#5A6072" />
              <Text className="flex-1 font-sans text-base ml-3 text-[#181B21] dark:text-[#EEF0F3]">
                Capsule Reminders
              </Text>
              <Switch
                value={notificationsEnabled}
                onValueChange={async (val) => {
                  setNotificationsEnabled(val);
                  if (!val) {
                    await NotificationService.cancelAll();
                  } else {
                    const permitted = await NotificationService.requestPermission();
                    if (!permitted) {
                      setNotificationsEnabled(false);
                    }
                  }
                }}
                trackColor={{ false: "#C9CFD8", true: "#3B608F" }}
                thumbColor="#EEF0F3"
              />
            </View>
          </View>
        </View>

        {/* Biometrics */}
        <View className="mb-6">
          <Text className="font-heading text-sm font-semibold text-[#5A6072] uppercase tracking-wider mb-3 px-1">
            Security
          </Text>
          <View className="bg-[#EEF0F3] dark:bg-[#1C2027] rounded-2xl overflow-hidden border border-[#C9CFD8]/50">
            <View className="flex-row items-center px-4 py-4">
              <Fingerprint size={20} color="#5A6072" />
              <Text className="flex-1 font-sans text-base ml-3 text-[#181B21] dark:text-[#EEF0F3]">
                Lock with Biometrics
              </Text>
              <Switch
                value={biometricEnabled}
                onValueChange={handleToggleBiometric}
                trackColor={{ false: "#C9CFD8", true: "#3B608F" }}
                thumbColor="#EEF0F3"
              />
            </View>
          </View>
        </View>

        {/* Danger Zone */}
        <View className="mb-6">
          <Text className="font-heading text-sm font-semibold text-[#5A6072] uppercase tracking-wider mb-3 px-1">
            Danger Zone
          </Text>
          <View className="bg-[#EEF0F3] dark:bg-[#1C2027] rounded-2xl overflow-hidden border border-[#C9CFD8]/50">
            <TouchableOpacity
              onPress={() => setShowDeleteDialog(true)}
              className="flex-row items-center px-4 py-4"
            >
              <Trash2 size={20} color="#EF4444" />
              <Text className="flex-1 font-sans text-base ml-3 text-red-500">
                Delete All Data
              </Text>
              <ChevronRight size={18} color="#5A6072" />
            </TouchableOpacity>
          </View>
        </View>

        <View className="items-center pb-8">
          <Text className="font-sans text-xs text-[#5A6072]">
            TimeCapsule v1.0.0
          </Text>
          <Text className="font-sans text-xs text-[#5A6072] mt-1">
            All data stored locally on this device
          </Text>
        </View>
      </ScrollView>
    </>
  );
}
