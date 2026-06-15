export type CapsuleStatus = "sealed" | "ready" | "opened";

export interface Capsule {
  id: string;
  title: string;
  content: string;
  createdAt: number;
  openAt: number;
  status: CapsuleStatus;
  openedAt: number | null;
  tags: string[];
  imageUris: string[];
  notificationId: string | null;
}

export interface CreateCapsuleInput {
  title: string;
  content: string;
  openAt: number;
  tags?: string[];
  imageUris?: string[];
}

export interface CapsuleStats {
  total: number;
  sealed: number;
  ready: number;
  opened: number;
}

export type PresetDate = {
  label: string;
  value: number;
};
