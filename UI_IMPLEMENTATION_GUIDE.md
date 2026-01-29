# UI Implementation Guide - What You'll See

## App Launch Sequence

1. **Splash Screen** (1-2 seconds)
   - Biometric fingerprint prompt (if enabled)
   - Loading animation

2. **Dashboard (Home Tab)** 
   - Shows immediately after authentication
   - Full light theme with teal accents

## Screen Layouts

### 1. Home Dashboard (Default View)

```
┌─────────────────────────────────────────┐
│ Good Morning, Alex! 🌅                  │
│              [Profile]                  │
├─────────────────────────────────────────┤
│   Balance                               │
│   € 4,120.50                            │
│   [Gradient Teal Card]                  │
├─────────────────────────────────────────┤
│  Income          │      Expenses        │
│  + € 3,500.00    │    - € 1,200.50     │
│  [Green Card]    │    [Red Card]       │
├─────────────────────────────────────────┤
│ Quick Actions                           │
│ [📸 Scan] [💸 Transfer]                │
├─────────────────────────────────────────┤
│ Recent Transactions                     │
│ 🍔 Food             - € 45.50           │
│ 🚕 Transport        - € 25.00           │
│ 💼 Salary          + € 3,500.00         │
│ 🛍️  Shopping         - € 120.00         │
│ ⚡ Utilities        - € 85.00           │
│ 🎬 Entertainment    - € 35.50           │
│ 🏥 Health          - € 120.00           │
│ 🏠 Housing          - € 850.00          │
│ [More items available by scrolling]     │
├─────────────────────────────────────────┤
│ [Home] [Budget] [Reports] [Profile]  [+] │
└─────────────────────────────────────────┘
```

### 2. Add Transaction Modal (Tap FAB)

```
┌─────────────────────────────────────────┐
│         Add Transaction                 │
│  [🔄 Expense] [💰 Income]              │
├─────────────────────────────────────────┤
│         €  0.00                         │
│      [Input Field]                      │
├─────────────────────────────────────────┤
│        Select Category                  │
│  🍔     🚕     🛍️     ⚡              │
│ Food  Transport Shopping Utilities     │
│                                        │
│  🎬     🏥     🏠     ⋯               │
│ Entertain Health Housing Other        │
├─────────────────────────────────────────┤
│ 📅 December 23, 2024                   │
│ 📝 Add a note...                       │
│ 💳 Select Account                      │
├─────────────────────────────────────────┤
│           [💾 Save Transaction]        │
│           [⏱️  Save for Later]         │
│           [❌ Skip]                    │
└─────────────────────────────────────────┘
```

### 3. Budget Tab

```
┌─────────────────────────────────────────┐
│        Monthly Budget                   │
│        [Donut Chart 70%]                │
│                                        │
│     Budget:  € 3,000.00                │
│     Spent:   € 2,100.00                │
│     Remaining: € 900.00                │
├─────────────────────────────────────────┤
│ Category Budgets                        │
│ 🍔 Food                €250  [█████─]   │
│ 🚕 Transport          €300  [███──────]  │
│ 💼 Salary             N/A   [────────]  │
│ 🛍️  Shopping           €500  [██████]    │
│ ⚡ Utilities          €150  [████━━━]   │
│ 🎬 Entertainment      €200  [██────]    │
│ 🏥 Health            €100  [██───]     │
│ 🏠 Housing           €1,000 [██████]    │
├─────────────────────────────────────────┤
│ [Home] [Budget] [Reports] [Profile]  [+] │
└─────────────────────────────────────────┘
```

### 4. Analytics/Reports Tab

```
┌─────────────────────────────────────────┐
│ Filters                                 │
│ [Today] [Week] [Month] [Custom]        │
│ [✓Food] [✓Transport] [✓Shopping] [✓...] │
├─────────────────────────────────────────┤
│ Total Spent This Month                  │
│      € 2,100.50                        │
├─────────────────────────────────────────┤
│ Daily Spending Chart                    │
│ [Bar Chart showing days 1-31]          │
├─────────────────────────────────────────┤
│ Top Spending Categories                 │
│ 1. 🏠 Housing      € 850.00 (40%)      │
│ 2. 🛍️  Shopping     € 420.00 (20%)     │
│ 3. 🍔 Food        € 350.00 (17%)      │
│ 4. ⚡ Utilities     € 240.00 (11%)     │
│ 5. 🚕 Transport    € 240.00 (12%)     │
├─────────────────────────────────────────┤
│ [Home] [Budget] [Reports] [Profile]  [+] │
└─────────────────────────────────────────┘
```

### 5. Settings/Profile Tab

```
┌─────────────────────────────────────────┐
│ User Profile                            │
│          [👤 Profile Image]             │
│          Alex Johnson                   │
│          alex@email.com                 │
├─────────────────────────────────────────┤
│ Account Settings                        │
│ 💼 Account Details           >          │
│ 🔐 Security & Privacy        >          │
│ 📱 Notifications             >          │
│ 🎨 Theme                     >          │
│ 📊 Data & Export             >          │
│ ❓ Help & Support            >          │
├─────────────────────────────────────────┤
│ [Logout]                                │
├─────────────────────────────────────────┤
│ [Home] [Budget] [Reports] [Profile]  [+] │
└─────────────────────────────────────────┘
```

## Interactive Elements

### Navigation Bar
- **Bottom bar** with 4 icons + text labels
- **Teal color** (#2B7A91) when tab is active
- **Grey color** (#6B7280) when tab is inactive
- **Smooth transition** between tabs

### FAB (Floating Action Button)
- **Center-positioned** above nav bar
- **Teal color** (#2B7A91)
- **Elevated shadow**
- **Tap to open transaction form**

### Transaction Form
- **Toggle switch**: Expense (default) / Income
  - Selected toggle shows **teal background**
  - Unselected toggle shows **grey background**
- **Category grid**: 4 columns of circular icons
  - Category selected = **border highlight** + **teal outline**
  - Category unselected = **grey circle**
- **Date picker**: Tap to open calendar
- **Save button**: Full-width teal button

### Filters
- **Date range buttons**: Selected shows **filled teal background**
- **Category filters**: Checked shows **teal checkmark**

## Color Key

| Color | Hex | Usage |
|-------|-----|-------|
| Teal | #2B7A91 | Primary UI, selected states, buttons |
| White | #FFFFFF | Backgrounds |
| Light Grey | #F8FAFB | Input fields, secondary surfaces |
| Medium Grey | #6B7280 | Secondary text, inactive states |
| Dark Grey | #1F2937 | Primary text |
| Green | #10B981 | Income, positive amounts |
| Red | #EF4444 | Expenses, negative amounts |

## Animation & Feedback

### Instant Feedback
- ✅ Buttons change color immediately on tap
- ✅ Filters show selection state instantly
- ✅ Toggle switches animate smoothly
- ✅ Category selection shows border highlight

### Transitions
- ✅ Smooth tab transitions (200ms fade)
- ✅ Modal slides up from bottom
- ✅ Modal slides down to close

## Testing Checklist

### Visual Verification
- [ ] Light theme applied globally (no dark backgrounds)
- [ ] Teal color (#2B7A91) used consistently for primary actions
- [ ] All text readable on white background
- [ ] Icons display correctly with proper colors
- [ ] Spacing and alignment matches mockup

### Interaction Testing
- [ ] FAB opens transaction form
- [ ] Form closes when Save is tapped
- [ ] Category selection shows visual feedback
- [ ] Date picker opens on tap
- [ ] Navigation tabs switch screens
- [ ] Filters show instant selection state

### Data Testing
- [ ] Balance displays correctly
- [ ] Transactions appear in list
- [ ] Budget calculations correct
- [ ] Charts render properly
- [ ] No console errors

## Performance Targets

- **App startup**: < 3 seconds
- **Form open**: Instant (< 500ms)
- **Tab switch**: < 300ms
- **List scroll**: Smooth, 60 FPS
- **Database operations**: < 500ms

---

**Implementation Date**: December 23, 2024  
**Design System**: Material 3 Light Theme  
**Status**: Ready for User Testing ✅
