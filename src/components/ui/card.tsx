import { View, type ViewProps } from "react-native";

type CardProps = ViewProps & {
  variant?: "default" | "elevated" | "outline";
};

export function Card({ variant = "default", className, style, ...props }: CardProps) {
  const variantClasses = {
    default: "bg-cream dark:bg-[#1C2027]",
    elevated: "bg-cream dark:bg-[#1C2027] shadow-md",
    outline: "bg-cream dark:bg-[#1C2027] border border-border",
  };

  return (
    <View
      className={`rounded-xl p-4 ${variantClasses[variant]} ${className ?? ""}`}
      style={style}
      {...props}
    />
  );
}
