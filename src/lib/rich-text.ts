import { generateId } from "@/lib/id";

export type BlockType = "heading" | "paragraph";

export interface ContentBlock {
  id: string;
  type: BlockType;
  underline: boolean;
  text: string;
}

export function createEmptyBlock(
  type: BlockType = "paragraph",
  underline = false
): ContentBlock {
  return { id: generateId(), type, underline, text: "" };
}

// Capsules created before rich text existed have plain-text `content`.
// JSON.parse on a plain sentence throws, which is exactly the signal we use
// to fall back to wrapping it as a single paragraph block.
export function parseBlocks(raw: string): ContentBlock[] {
  try {
    const parsed = JSON.parse(raw);
    if (Array.isArray(parsed) && parsed.length > 0 && isBlockLike(parsed[0])) {
      return parsed.map((b) => ({
        id: typeof b.id === "string" ? b.id : generateId(),
        type: b.type === "heading" ? "heading" : "paragraph",
        underline: !!b.underline,
        text: typeof b.text === "string" ? b.text : "",
      }));
    }
  } catch {
    // fall through to plain-text wrapping below
  }
  return [{ id: generateId(), type: "paragraph", underline: false, text: raw }];
}

function isBlockLike(value: unknown): value is Partial<ContentBlock> {
  return (
    typeof value === "object" &&
    value !== null &&
    "text" in value &&
    "type" in value
  );
}

export function serializeBlocks(blocks: ContentBlock[]): string {
  return JSON.stringify(blocks);
}

export function blocksToPlainText(blocks: ContentBlock[]): string {
  return blocks
    .map((b) => b.text)
    .filter(Boolean)
    .join("\n");
}

export function blocksHaveContent(blocks: ContentBlock[]): boolean {
  return blocks.some((b) => b.text.trim().length > 0);
}
