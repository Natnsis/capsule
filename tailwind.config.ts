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
        // Semantic roles — keep usage consistent across the app:
        //   cream / brown            -> screen background (light / dark)
        //   card / brown.card        -> elevated surface: cards, modals, sheets (light / dark)
        //   muted / brown.light      -> secondary fill: chips, inactive pills, input bg (light / dark)
        //   brown / cream            -> primary text (light / dark)
        //   muted-foreground         -> secondary/caption text (both modes, no dark: variant needed)
        //   border / brown.light     -> hairline borders (light / dark)
        //   sage                     -> primary interactive accent: buttons, active nav, links, selection
        //   secondary                -> hero/highlight accent, used sparingly (1-2 spots per screen)
        //   destructive              -> delete/error actions only
        // Non-className color props (icon `color=`, placeholderTextColor, Switch trackColor)
        // must use the matching constant in src/constants/colors.ts instead of retyping hex.
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
          card: "#1C2027",
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
