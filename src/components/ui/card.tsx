import { View, type ViewProps } from "react-native";

type CardProps = ViewProps & {
  variant?: "default" | "elevated" | "outline";
};

export function Card({ variant = "default", className, style, ...props }: CardProps) {
  const variantClasses = {
    default: "bg-cream dark:bg-[#4E4449]",
    elevated: "bg-cream dark:bg-[#4E4449] shadow-md",
    outline: "bg-cream dark:bg-[#4E4449] border border-border",
  };

  return (
    <View
      className={`rounded-xl p-4 ${variantClasses[variant]} ${className ?? ""}`}
      style={style}
      {...props}
    />
  );
}
