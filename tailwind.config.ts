import type { Config } from "tailwindcss";

export default {
  content: ["./src/**/*.{ts,tsx}"],
  presets: [require("nativewind/preset")],
  darkMode: "class",
  theme: {
    extend: {
      fontFamily: {
        sans: ["Outfit", "sans-serif"],
        heading: ["Outfit", "sans-serif"],
      },
      borderRadius: {
        sm: "0.375rem",
        md: "0.5rem",
        lg: "0.625rem",
        xl: "0.875rem",
        "2xl": "1.125rem",
        "3xl": "1.375rem",
        "4xl": "1.625rem",
      },
      colors: {
        cream: "#EEF0F3",
        sage: {
          DEFAULT: "#3B608F",
          light: "#6B87B0",
          dark: "#2C4A6D",
        },
        brown: {
          DEFAULT: "#181B21",
          light: "#353C48",
          dark: "#0F1216",
        },
        background: "#EEF0F3",
        foreground: "#181B21",
        card: "#FFFFFF",
        "card-foreground": "#181B21",
        popover: "#FFFFFF",
        "popover-foreground": "#181B21",
        primary: {
          DEFAULT: "#3B608F",
          foreground: "#FFFFFF",
        },
        secondary: {
          DEFAULT: "#B8694A",
          foreground: "#FFFFFF",
        },
        muted: {
          DEFAULT: "#E8EAEE",
          foreground: "#5A6072",
        },
        accent: {
          DEFAULT: "#D8E2EE",
          foreground: "#1F3A5C",
        },
        destructive: {
          DEFAULT: "#B8332E",
          foreground: "#FFFFFF",
        },
        border: "#C9CFD8",
        input: "#C9CFD8",
        ring: "#6B87B0",
        sidebar: {
          DEFAULT: "#E2E5EA",
          foreground: "#181B21",
          primary: "#3B608F",
          "primary-foreground": "#FFFFFF",
          accent: "#D8E2EE",
          "accent-foreground": "#1F3A5C",
          border: "#C9CFD8",
          ring: "#6B87B0",
        },
      },
    },
  },
  plugins: [],
} satisfies Config;
