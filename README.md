# WEAPON MASTERY RPG

Action RPG แนว Weapon Mastery / Loot Progression ที่เน้นการต่อสู้แบบจับจังหวะ
ภาพ Pixel Art มุมมอง Top-down 3/4

## ข้อมูลโครงการ

| หัวข้อ | รายละเอียด |
|---|---|
| Engine | Godot 4.7 (Renderer: GL Compatibility) |
| ภาษา | GDScript |
| แพลตฟอร์ม | Windows PC |
| ความละเอียดภายใน | 480×270 (Pixel Art) |
| สถานะ | Phase 0 — Project Preparation |

## วิธีเปิดโปรเจกต์

1. ติดตั้ง Godot 4.7
2. เปิด Godot → Import → เลือกไฟล์ `project.godot` ในโฟลเดอร์นี้
3. กด F5 เพื่อรันเกม

## โครงสร้างโฟลเดอร์

```
assets/     ไฟล์ภาพ เสียง เอฟเฟกต์ และฟอนต์
data/       ข้อมูลเกม (Godot Resource .tres) เช่น อาวุธ ศัตรู ไอเทม ทักษะ
docs/       เอกสารการพัฒนา (Master Development Flow, GDD)
scenes/     ไฟล์ฉาก .tscn แยกตาม characters / enemies / levels / ui
scripts/    ไฟล์โค้ด .gd แยกตาม player / enemies / systems / ui
```

## กติกาการตั้งชื่อ

- ไฟล์และโฟลเดอร์ใช้ `snake_case` ตัวพิมพ์เล็กทั้งหมด เช่น `test_arena.tscn`, `health_component.gd`
- ชื่อ Node ในฉากใช้ `PascalCase` เช่น `Player`, `Hitbox`

## กติกาการ Commit

- Commit ทุกครั้งที่ทำงานย่อยเสร็จหนึ่งชิ้น
- ขึ้นต้นข้อความด้วย Task ID จากเอกสาร Master Development Flow เช่น
  - `0.7: add README`
  - `2.3: 8-direction movement`
  - `docs: update Master Development Flow v1.1`
- Push ขึ้น GitHub อย่างน้อยวันละครั้ง

## เอกสาร

- `docs/WEAPON_MASTERY_Master_Development_Flow_v1.1.docx` — แผนการพัฒนาหลัก ลำดับงาน และ Change Log
