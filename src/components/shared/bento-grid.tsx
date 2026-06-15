import { View, type ViewProps } from "react-native";

interface BentoGridProps extends ViewProps {
  children: React.ReactNode;
}

export function BentoGrid({ children, className, ...props }: BentoGridProps) {
  return (
    <View className={`flex-row gap-3 px-4 ${className ?? ""}`} {...props}>
      {children}
    </View>
  );
}

interface BentoColumnProps extends ViewProps {
  children: React.ReactNode;
  flex?: number;
}

export function BentoColumn({
  children,
  flex = 1,
  className,
  ...props
}: BentoColumnProps) {
  return (
    <View
      className={`gap-3 ${className ?? ""}`}
      style={{ flex }}
      {...props}
    >
      {children}
    </View>
  );
}
