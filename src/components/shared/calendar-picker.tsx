import { useState, useMemo } from "react";
import { View, Text, Modal, TouchableOpacity, Pressable } from "react-native";
import { ChevronLeft, ChevronRight } from "lucide-react-native";
import {
  startOfMonth,
  endOfMonth,
  startOfWeek,
  endOfWeek,
  eachDayOfInterval,
  format,
  addMonths,
  subMonths,
  isSameMonth,
  isSameDay,
  isToday,
} from "date-fns";

const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

interface CalendarPickerProps {
  visible: boolean;
  currentValue: number | null;
  onSelect: (timestamp: number) => void;
  onClose: () => void;
}

export function CalendarPicker({ visible, currentValue, onSelect, onClose }: CalendarPickerProps) {
  const today = useMemo(() => new Date(), []);
  const initialDate = currentValue ? new Date(currentValue) : today;
  const [viewDate, setViewDate] = useState(initialDate);

  const days = useMemo(() => {
    const start = startOfWeek(startOfMonth(viewDate));
    const end = endOfWeek(endOfMonth(viewDate));
    return eachDayOfInterval({ start, end });
  }, [viewDate]);

  return (
    <Modal transparent visible={visible} animationType="none" onRequestClose={onClose}>
      <Pressable className="flex-1 bg-black/50 justify-center items-center px-6" onPress={onClose}>
        <Pressable
          onPress={(e) => e.stopPropagation()}
          className="bg-[#F2EFEA] dark:bg-[#4E4449] rounded-3xl w-full max-w-sm overflow-hidden"
        >
          {/* Header */}
          <View className="flex-row items-center justify-between px-6 pt-6 pb-2">
            <TouchableOpacity
              onPress={() => setViewDate((d) => subMonths(d, 1))}
              className="w-9 h-9 rounded-full bg-[#E4E0DA] dark:bg-[#5E4F53] items-center justify-center"
            >
              <ChevronLeft size={18} color="#41393C" />
            </TouchableOpacity>
            <Text className="font-heading text-lg font-semibold text-[#41393C] dark:text-[#F2EFEA]">
              {format(viewDate, "MMMM yyyy")}
            </Text>
            <TouchableOpacity
              onPress={() => setViewDate((d) => addMonths(d, 1))}
              className="w-9 h-9 rounded-full bg-[#E4E0DA] dark:bg-[#5E4F53] items-center justify-center"
            >
              <ChevronRight size={18} color="#41393C" />
            </TouchableOpacity>
          </View>

          {/* Weekday headers */}
          <View className="flex-row px-6 pt-2 pb-1">
            {WEEKDAYS.map((day) => (
              <View key={day} className="items-center" style={{ width: "14.28%" }}>
                <Text className="font-sans text-xs font-semibold text-[#7A6E71]">{day}</Text>
              </View>
            ))}
          </View>

          {/* Day grid */}
          <View className="flex-row flex-wrap px-6 pb-6 pt-1">
            {days.map((day, idx) => {
              const sameMonth = isSameMonth(day, viewDate);
              const selected = currentValue ? isSameDay(day, new Date(currentValue)) : false;
              const isTodayDay = isToday(day);
              const past = day < today && !isSameDay(day, today);

              if (!sameMonth) {
                return (
                  <View key={idx} style={{ width: "14.28%", aspectRatio: 1 }} className="items-center justify-center" />
                );
              }

              return (
                <TouchableOpacity
                  key={idx}
                  onPress={() => onSelect(day.getTime())}
                  disabled={past}
                  style={{ width: "14.28%", aspectRatio: 1 }}
                  className={`items-center justify-center rounded-full ${selected ? "bg-sage" : isTodayDay ? "bg-sage/20" : ""}`}
                >
                  <Text
                    className={`font-sans text-sm ${
                      selected
                        ? "text-[#F2EFEA] font-semibold"
                        : isTodayDay
                          ? "text-sage font-semibold"
                          : past
                            ? "text-[#D5D0CA] dark:text-[#5E4F53]"
                            : "text-[#41393C] dark:text-[#F2EFEA]"
                    }`}
                  >
                    {format(day, "d")}
                  </Text>
                </TouchableOpacity>
              );
            })}
          </View>
        </Pressable>
      </Pressable>
    </Modal>
  );
}
