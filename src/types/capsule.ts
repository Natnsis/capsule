export type CapsuleStatus = "draft" | "sealed" | "ready" | "opened";

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
  notificationIds: string[];
  requireBiometric: boolean;
}

export interface CreateCapsuleInput {
  title: string;
  content: string;
  openAt: number;
  tags?: string[];
  imageUris?: string[];
  requireBiometric?: boolean;
  status?: "draft" | "sealed";
}

export interface CapsuleStats {
  total: number;
  drafts: number;
  sealed: number;
  ready: number;
  opened: number;
}

export type PresetDate = {
  label: string;
  value: number;
};
