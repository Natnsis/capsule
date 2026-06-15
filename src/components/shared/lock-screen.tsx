import { useEffect, useState } from "react";
import { View, Text, TouchableOpacity, Image } from "react-native";
import { Fingerprint } from "lucide-react-native";
import { BiometricService } from "@/services/biometric-service";

interface LockScreenProps {
  onUnlock: () => void;
}

export function LockScreen({ onUnlock }: LockScreenProps) {
  const [attempting, setAttempting] = useState(false);
  const [error, setError] = useState(false);

  const handleAuth = async () => {
    if (attempting) return;
    setAttempting(true);
    setError(false);

    const ok = await BiometricService.authenticate();
    if (ok) {
      onUnlock();
    } else {
      setError(true);
    }
    setAttempting(false);
  };

  useEffect(() => {
    handleAuth();
  }, []);

  return (
    <View className="flex-1 bg-[#41393C] items-center justify-center px-6">
      <Image
        source={require("@/../assets/images/logo.png")}
        className="w-16 h-16 mb-4"
        resizeMode="contain"
      />
      <Text className="font-heading text-3xl font-bold text-[#F2EFEA] mb-2">
        TimeCapsule
      </Text>
      <Text className="font-sans text-base text-[#D5D0CA] mb-12 text-center">
        Your memories are locked
      </Text>

      <TouchableOpacity
        onPress={handleAuth}
        disabled={attempting}
        className="bg-sage rounded-full w-20 h-20 items-center justify-center mb-4"
      >
        <Fingerprint size={36} color="#F2EFEA" />
      </TouchableOpacity>

      {error && (
        <Text className="font-sans text-sm text-red-400 mt-4 text-center">
          Authentication failed. Try again.
        </Text>
      )}

      <Text className="font-sans text-sm text-[#7A6E71] mt-4 text-center">
        Tap the fingerprint to unlock
      </Text>
    </View>
  );
}
