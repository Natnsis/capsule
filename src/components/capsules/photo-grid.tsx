import { View, Text, Image } from "react-native";

interface PhotoGridProps {
  imageUris: string[];
  maxDisplay?: number;
}

export function PhotoGrid({ imageUris, maxDisplay = 3 }: PhotoGridProps) {
  if (imageUris.length === 0) return null;

  const display = imageUris.slice(0, maxDisplay);
  const remaining = imageUris.length - maxDisplay;

  return (
    <View className="flex-row gap-2">
      {display.map((uri, index) => (
        <Image
          key={index}
          source={{ uri }}
          className="w-16 h-16 rounded-lg"
        />
      ))}
      {remaining > 0 && (
        <View className="w-16 h-16 rounded-lg bg-muted items-center justify-center">
          <View className="font-sans text-sm text-muted-foreground font-semibold">
            +{remaining}
          </View>
        </View>
      )}
    </View>
  );
}
