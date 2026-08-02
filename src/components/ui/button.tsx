import {
  TouchableOpacity,
  Text,
  type TouchableOpacityProps,
  type TextProps,
  ActivityIndicator,
} from "react-native";

type ButtonProps = TouchableOpacityProps & {
  variant?: "primary" | "secondary" | "ghost" | "outline";
  size?: "sm" | "md" | "lg";
  loading?: boolean;
  label: string;
  labelProps?: TextProps;
};

export function Button({
  variant = "primary",
  size = "md",
  loading = false,
  label,
  className,
  disabled,
  labelProps,
  ...props
}: ButtonProps) {
  const variantClasses = {
    primary: "bg-sage",
    secondary: "bg-secondary",
    ghost: "bg-transparent",
    outline: "bg-transparent border border-sage",
  };

  const sizeClasses = {
    sm: "px-4 py-2",
    md: "px-6 py-3",
    lg: "px-8 py-4",
  };

  const labelVariantColors = {
    primary: "text-cream",
    secondary: "text-brown",
    ghost: "text-sage",
    outline: "text-sage",
  };

  return (
    <TouchableOpacity
      className={`rounded-full items-center justify-center flex-row ${variantClasses[variant]} ${sizeClasses[size]} ${disabled || loading ? "opacity-50" : ""} ${className ?? ""}`}
      disabled={disabled || loading}
      {...props}
    >
      {loading && <ActivityIndicator className="mr-2" color={variant === "primary" ? "#EEF0F3" : "#3B608F"} />}
      <Text
        className={`font-sans font-semibold ${labelVariantColors[variant]} ${size === "lg" ? "text-lg" : size === "sm" ? "text-sm" : "text-base"}`}
        {...labelProps}
      >
        {label}
      </Text>
    </TouchableOpacity>
  );
}
