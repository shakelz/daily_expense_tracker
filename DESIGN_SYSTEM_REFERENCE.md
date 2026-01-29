# Light Theme Material 3 Design System - Visual Reference

## Color Palette

### Primary Colors
```
┌──────────────────────────────────────┐
│  Primary Teal                        │
│  #2B7A91                            │
│  RGB(43, 122, 145)                  │
│  Used for: Buttons, selected items,  │
│  icons, links, accents               │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│  Teal (Darker - Gradient)           │
│  #1E5A6E                            │
│  RGB(30, 90, 110)                   │
│  Used for: Gradient backgrounds,     │
│  hover states                        │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│  White (Primary Background)          │
│  #FFFFFF                            │
│  RGB(255, 255, 255)                 │
│  Used for: Main app background,      │
│  cards, surfaces                     │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│  Light Grey (Surfaces)              │
│  #F8FAFB                            │
│  RGB(248, 250, 251)                 │
│  Used for: Input backgrounds,        │
│  secondary surfaces                  │
└──────────────────────────────────────┘
```

### Status Colors
```
┌──────────────────────────────────────┐
│  Income Green                        │
│  #10B981                            │
│  RGB(16, 185, 129)                  │
│  Used for: Income amounts, positive   │
│  indicators                          │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│  Expense Red                         │
│  #EF4444                            │
│  RGB(239, 68, 68)                   │
│  Used for: Expense amounts, negative │
│  indicators, errors                  │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│  Warning Orange                      │
│  #F97316                            │
│  RGB(249, 115, 22)                  │
│  Used for: Budget warnings,          │
│  caution indicators                  │
└──────────────────────────────────────┘
```

### Text Colors
```
┌──────────────────────────────────────┐
│  Text Dark (Primary)                │
│  #1F2937                            │
│  RGB(31, 41, 55)                    │
│  Used for: Headings, body text       │
└──────────────────────────────────────┘

┌──────────────────────────────────────┐
│  Text Medium (Secondary)            │
│  #6B7280                            │
│  RGB(107, 114, 128)                 │
│  Used for: Labels, secondary info    │
└──────────────────────────────────────┘
```

---

## Typography System

### Heading 1 (Page Title)
- Font: Poppins
- Size: 28px
- Weight: Bold (700)
- Example: "Your Finances", "Analysis"

### Heading 2 (Section Title)
- Font: Poppins
- Size: 16px
- Weight: Bold (700)
- Example: "Recent Transactions", "Quick Actions"

### Body Text (Regular)
- Font: Poppins
- Size: 14px
- Weight: Regular (400)
- Example: Transaction titles, descriptions

### Labels (Small)
- Font: Poppins
- Size: 12px
- Weight: Medium (500)
- Example: Field labels, category names

### Caption (Extra Small)
- Font: Poppins
- Size: 11px
- Weight: Regular (400)
- Example: Dates, secondary info

---

## Component Library

### Buttons

#### Primary Button
```
Background: #2B7A91 (Teal)
Text: White
Padding: 16px horizontal × 14px vertical
Border Radius: 8-12px
Shadow: Elevation 2-4
Font: Poppins 14px Bold
```

#### Secondary Button (Outlined)
```
Background: Transparent/Light
Border: 1px #2B7A91
Text: #2B7A91
Padding: 14px horizontal × 12px vertical
Border Radius: 8px
Font: Poppins 13px Medium
```

### Cards

#### Large Card (Main Content)
```
Background: #FFFFFF
Border: None or 1px #E5E7EB
Border Radius: 24px
Padding: 16-24px
Shadow: 0px 2px 8px rgba(0,0,0,0.04)
Elevation: 2
```

#### List Item Card
```
Background: #FFFFFF
Border: 1px #E5E7EB
Border Radius: 16px
Padding: 12px
Shadow: 0px 1px 4px rgba(0,0,0,0.04)
Elevation: 1
```

### Input Fields

#### Text Input
```
Background: #F8FAFB
Border: None
Border Radius: 16px
Padding: 14px 16px
Font: Poppins 14px Regular
Text Color: #1F2937
Placeholder: #6B7280
```

### Progress Bar

#### Linear Progress
```
Height: 6px
Border Radius: 4px
Background: #F8FAFB
Progress Color: #2B7A91 (or #F97316, #EF4444 based on state)
```

#### Circular Progress
```
Size: Variable
Color: #2B7A91
Stroke Width: 4px
Background: #F8FAFB
```

---

## Spacing System

### Margins & Padding
```
Extra Small (xs):  4px
Small (sm):        8px
Medium (md):      12px
Base (base):      16px
Large (lg):       20px
Extra Large (xl): 24px
Double (2xl):     32px
```

### Common Spacing Patterns

#### Screen Padding
```
Horizontal: 16px
Vertical (top/bottom): 12px
```

#### Card Spacing
```
Padding inside: 16-24px
Gap between cards: 12px
```

#### Component Gap
```
Icon to text: 8-12px
Label to input: 8px
Section gap: 24-32px
```

---

## Layout Patterns

### Dashboard Layout
```
┌─────────────────────────────────┐
│    Header (Profile + Greeting)  │
│    ┌───────┐  "Good Morning"    │
│    │       │  Your Finances     │
│    └───────┘                    │
├─────────────────────────────────┤
│  ╔═════════════════════════════╗│
│  ║  €2,450.50                  ║│
│  ║  Available Balance           ║│
│  ╚═════════════════════════════╝│
├─────────────────────────────────┤
│ ┌──────────────┐ ┌────────────┐ │
│ │ Income       │ │ Expense    │ │
│ │ €5,000.00    │ │ €2,550.00  │ │
│ └──────────────┘ └────────────┘ │
├─────────────────────────────────┤
│ ┌──────────────┐ ┌────────────┐ │
│ │ 📷 Scan      │ │ 💳 Transfer│ │
│ │ Receipt      │ │            │ │
│ └──────────────┘ └────────────┘ │
├─────────────────────────────────┤
│ Recent Transactions             │
│ ┌─────────────────────────────┐ │
│ │ 🍔 Lunch                    │ │
│ │ Food • Today       -€15.99  │ │
│ └─────────────────────────────┘ │
│ ┌─────────────────────────────┐ │
│ │ 🚗 Gas                      │ │
│ │ Transport • Yesterday -€45  │ │
│ └─────────────────────────────┘ │
└─────────────────────────────────┘
```

### Transaction Item
```
┌─────────────────────────────────────┐
│ ┌─────┐                             │
│ │  🍔 │ Lunch                  -€15 │
│ │     │ Food • Today                │
│ └─────┘                             │
└─────────────────────────────────────┘
```

### Budget Item
```
┌─────────────────────────────────────┐
│ Food                          45%   │
│ ████░░░░░░░░░░░░░░░░░░░░░░░░       │
│ €450 spent           €50 left       │
└─────────────────────────────────────┘
```

---

## Typography in Use

### Balance Card
```
┌─────────────────────────────────────┐
│ Available Balance         [12px md]  │
│ €2,450.50                 [40px bo] │
└─────────────────────────────────────┘
```

### Transaction List Item
```
┌─────────────────────────────────────┐
│ Lunch                     [14px bo] │
│ Food • Today              [12px md] │
│                    -€15.99 [14px bo]│
└─────────────────────────────────────┘
```

### Section Header
```
Recent Transactions          [16px bo]
See all                     [13px sem]
```

---

## Interactive States

### Button States

#### Default
```
Background: #2B7A91
Text: White
Shadow: Elevation 2
```

#### Hover
```
Background: #1E5A6E (darker teal)
Shadow: Elevation 4
```

#### Pressed
```
Background: #0D3A47
Shadow: Elevation 6
Scale: 0.98
```

#### Disabled
```
Background: #D1D5DB
Text: #9CA3AF
Opacity: 0.5
```

### Chip/Tag States

#### Default
```
Background: #F8FAFB
Border: 1px #E5E7EB
Text: #1F2937
```

#### Selected
```
Background: #2B7A91
Border: 2px #2B7A91
Text: White
Elevation: 2
```

### Input States

#### Default
```
Background: #F8FAFB
Border: None
Text: #1F2937
```

#### Focused
```
Background: #FFFFFF
Border: 1px #2B7A91
Text: #1F2937
Shadow: Elevation 1
```

#### Error
```
Background: #FEE2E2
Border: 1px #EF4444
Text: #DC2626
```

---

## Icon Usage

### Icon Colors
- **Primary**: #2B7A91 (Teal) - Main icons
- **Success**: #10B981 (Green) - Checkmarks
- **Error**: #EF4444 (Red) - Warnings
- **Neutral**: #6B7280 (Grey) - Disabled

### Icon Sizes
- **Large**: 28-32px (FAB, headers)
- **Medium**: 20-24px (Card icons, buttons)
- **Small**: 16-18px (Labels, navigation)

### Icon Background Circles
- Size: 40-48px
- Background Opacity: 10% of icon color
- Border Radius: 12px
- Example: 
  - Income Icon (#10B981): Green circle with 10% opacity
  - Expense Icon (#EF4444): Red circle with 10% opacity

---

## Animation Guidelines

### Transitions
- **Button Tap**: 100ms (scale + opacity)
- **Page Navigation**: 200-300ms (slide)
- **FAB Click**: 100ms (scale)
- **Expand/Collapse**: 150ms (height)

### Easing
- Default: EaseInOut
- Quick actions: EaseOut
- Dismissals: EaseIn

---

## Responsive Breakpoints

### Mobile (< 600px)
- Single column layout
- Full-width cards
- Stacked buttons
- Adjusted padding: 12px

### Tablet (600px - 900px)
- Two column layout
- Grid layouts
- Side-by-side components
- Adjusted padding: 16px

### Desktop (> 900px)
- Multi-column layout
- Maximum width container
- Expanded views
- Adjusted padding: 20-24px

---

## Design Tokens Summary

```dart
// Colors
const primaryTeal = Color(0xFF2B7A91);
const tealDark = Color(0xFF1E5A6E);
const white = Color(0xFFFFFFFF);
const surfaceLight = Color(0xFFF8FAFB);
const textDark = Color(0xFF1F2937);
const textMedium = Color(0xFF6B7280);
const incomeGreen = Color(0xFF10B981);
const expenseRed = Color(0xFFEF4444);
const warningOrange = Color(0xFFF97316);

// Fonts
const fontFamily = 'Poppins';
const headingStyle = TextStyle(
  fontSize: 28,
  fontWeight: FontWeight.bold,
);

// Radii
const radiusLarge = 24.0;
const radiusMedium = 16.0;
const radiusSmall = 12.0;

// Spacing
const spacingXS = 4.0;
const spacingSM = 8.0;
const spacingMD = 12.0;
const spacingBASE = 16.0;
const spacingLG = 20.0;
const spacingXL = 24.0;
const spacing2XL = 32.0;
```

---

## Quick Reference

| Element | Color | Size | Border Radius |
|---------|-------|------|---------------|
| Primary Button | #2B7A91 | 14px | 8px |
| Balance Card | Teal Gradient | 40px Text | 24px |
| List Item | #FFFFFF | 14px Text | 16px |
| Input Field | #F8FAFB | 14px Text | 16px |
| Icon Circle | Color@10% | 40-48px | 12px |
| Section Gap | - | - | - |
| Horizontal Padding | - | 16px | - |
| Vertical Padding | - | 12px | - |

---

Generated: January 28, 2026
Design System Version: 1.0
Status: Complete
