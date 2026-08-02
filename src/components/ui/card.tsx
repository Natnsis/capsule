import { View, type ViewProps } from "react-native";

type CardProps = ViewProps & {
  variant?: "default" | "elevated" | "outline";
};

export function Card({ variant = "default", className, style, ...props }: CardProps) {
  const variantClasses = {
    default: "bg-card dark:bg-brown-card",
    elevated: "bg-card dark:bg-brown-card shadow-md",
    outline: "bg-card dark:bg-brown-card border border-border/50 dark:border-brown-light/50",
  };

  return (
    <View
      className={`rounded-xl p-4 ${variantClasses[variant]} ${className ?? ""}`}
      style={style}
      {...props}
    />
  );
}
