// Mirrors the `colors` block in tailwind.config.ts. React Native props that
// can't take a className (icon `color=`, placeholderTextColor, Switch
// trackColor, ActivityIndicator color) must pull from here instead of
// retyping hex — keeps every literal color in the app traceable to one token.
export const colors = {
  cream: "#EEF0F3",
  brown: "#181B21",
  brownLight: "#353C48",
  brownDark: "#0F1216",
  brownCard: "#1C2027",
  sage: "#3B608F",
  sageLight: "#6B87B0",
  sageDark: "#2C4A6D",
  secondary: "#B8694A",
  muted: "#E8EAEE",
  mutedForeground: "#5A6072",
  border: "#C9CFD8",
  destructive: "#B8332E",
} as const;
