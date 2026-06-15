import { addMonths, addYears } from "date-fns";
import type { PresetDate } from "@/types/capsule";

export const PRESET_DATES: PresetDate[] = [
  { label: "1 month", value: addMonths(new Date(), 1).getTime() },
  { label: "6 months", value: addMonths(new Date(), 6).getTime() },
  { label: "1 year", value: addYears(new Date(), 1).getTime() },
  { label: "5 years", value: addYears(new Date(), 5).getTime() },
  { label: "10 years", value: addYears(new Date(), 10).getTime() },
];
