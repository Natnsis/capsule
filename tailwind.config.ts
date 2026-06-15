import type { Config } from "tailwindcss";

export default {
  content: ["./src/**/*.{ts,tsx}"],
  presets: [require("nativewind/preset")],
  darkMode: "class",
  theme: {
    extend: {
      fontFamily: {
        sans: ["Manrope", "sans-serif"],
        heading: ["Manrope", "sans-serif"],
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
        cream: "#F2EFEA",
        sage: {
          DEFAULT: "#82B090",
          light: "#A8C9B2",
          dark: "#5E7D66",
        },
        brown: {
          DEFAULT: "#41393C",
          light: "#5E4F53",
          dark: "#2E282A",
        },
        background: "#F2EFEA",
        foreground: "#41393C",
        card: "#F2EFEA",
        "card-foreground": "#41393C",
        popover: "#F2EFEA",
        "popover-foreground": "#41393C",
        primary: {
          DEFAULT: "#82B090",
          foreground: "#F2EFEA",
        },
        secondary: {
          DEFAULT: "#D0E4D7",
          foreground: "#41393C",
        },
        muted: {
          DEFAULT: "#E4E0DA",
          foreground: "#7A6E71",
        },
        accent: {
          DEFAULT: "#82B090",
          foreground: "#F2EFEA",
        },
        destructive: {
          DEFAULT: "#EF4444",
          foreground: "#FAFAFA",
        },
        border: "#D5D0CA",
        input: "#D5D0CA",
        ring: "#82B090",
        sidebar: {
          DEFAULT: "#E9E5DF",
          foreground: "#41393C",
          primary: "#82B090",
          "primary-foreground": "#F2EFEA",
          accent: "#D0E4D7",
          "accent-foreground": "#41393C",
          border: "#D5D0CA",
          ring: "#82B090",
        },
      },
    },
  },
  plugins: [],
} satisfies Config;
