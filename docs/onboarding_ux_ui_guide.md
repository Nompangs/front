# 🎨 NomPangS 온보딩 UX/UI 디자인 가이드

> **Based on Figma Design**: Figma 파일 분석을 통한 상세 디자인 시스템 및 구현 가이드  
> **Version**: 1.0  
> **Last Updated**: 2024-12-19  
> **Figma Nodes**: 14:3266 (인트로), 14:3218/14:3303/14:3361 (입력 화면)

## 📋 목차

1. [Design System Foundation](#-design-system-foundation)
2. [Screen Specifications](#-screen-by-screen-uxui-specification)
3. [UX Interaction Patterns](#-ux-interaction-patterns)
4. [Implementation Guidelines](#-implementation-guidelines)
5. [Accessibility](#-accessibility)

---

## 📐 Design System Foundation

### **Color Palette**

#### Primary Colors
| Color Name | Hex Code | Usage | Figma Reference |
|------------|----------|-------|-----------------|
| Cream Background | `#FDF7E9` | 메인 배경색 | 모든 화면 배경 |
| Purple Primary | `#6750A4` | 주요 액션 버튼 | CTA 버튼 배경 |
| Blue Input | `#57B3E6` | 입력 섹션 배경 | 입력 영역 하이라이트 |

#### Text Colors
| Color Name | Hex Code | Usage | Opacity |
|------------|----------|-------|---------|
| Text Primary | `#333333` | 주요 텍스트 | 90% |
| Text Secondary | `#BCBCBC` | 보조 텍스트 | 100% |
| Text Placeholder | `#B0B0B0` | 플레이스홀더 | 100% |

#### Status Colors
| Color Name | Hex Code | Usage |
|------------|----------|-------|
| Error Red | `#FD6262` | 에러 메시지 |
| Success Purple | `#DAB7FA` | 선택된 상태 |
| Surface White | `#FFFFFF` | 입력 필드 배경 |
| Surface Pink | `#FFD8F1` | 하단 영역 |

### **Typography Scale**

```scss
// Figma에서 추출된 폰트 스타일
$font-family: 'Pretendard', 'SF Pro Text', system-ui;
```

#### Headline Styles
| Style Name | Font Size | Font Weight | Line Height | Letter Spacing | Usage |
|------------|-----------|-------------|-------------|----------------|-------|
| Headline Large | 26px | 700 | 40px | 0 | 메인 메시지 |
| Headline Medium | 20px | 700 | 24px | 0 | 앱바 타이틀 |

#### Body Styles
| Style Name | Font Size | Font Weight | Line Height | Letter Spacing | Usage |
|------------|-----------|-------------|-------------|----------------|-------|
| Body Large | 16px | 500 | 24px | 0.15px | 버튼 라벨 |
| Body Medium | 14px | 400 | 16.7px | 0 | 보조 텍스트 |

#### Label Styles
| Style Name | Font Size | Font Weight | Line Height | Letter Spacing | Usage |
|------------|-----------|-------------|-------------|----------------|-------|
| Label Small | 12px | 500 | 14.32px | 0 | 건너뛰기 버튼 |
| Label Error | 10px | 700 | 11.93px | 0 | 에러 메시지 |

### **Spacing System**

| Token | Value | Usage |
|-------|-------|-------|
| `space-xs` | 8px | 최소 간격 |
| `space-sm` | 12px | 입력 필드 내부 간격 |
| `space-md` | 16px | 기본 패딩 |
| `space-lg` | 20px | 섹션 간 간격 |
| `space-xl` | 24px | 아이콘 크기 |
| `space-2xl` | 40px | 주요 섹션 간격 |
| `space-3xl` | 56px | 버튼 높이 |

### **Component Dimensions**

| Component | Width | Height | Border Radius |
|-----------|-------|--------|---------------|
| Primary Button | 343px | 56px | 100px (fully rounded) |
| Input Field | flexible | 55px | 40px (large rounded) |
| Screen Container | 375px | 812px | 28px |
| Character Preview | 80px | 80px | 40px (circle) |

---

## 📱 Screen-by-Screen UX/UI Specification

### **1. 온보딩 인트로 화면 (Figma: 14:3266)**

#### Layout Structure
```
┌─────────────────────────────────────┐
│ Status Bar (44px)                   │
├─────────────────────────────────────┤
│ Navigation Bar (60px)               │
│ ┌─────┐ 성격 조제 연금술! ┌────────┐ │
│ │ ←   │                    │건너뛰기│ │
│ └─────┘                    └────────┘ │
├─────────────────────────────────────┤
│ Main Content (expanded)             │
│                                     │
│    ┌───┐  ┌───┐  ┌───┐             │
│    │ ⭐ │  │ ⭐ │  │ ⭐ │             │
│    └───┘  └───┘  └───┘             │
│                                     │
│     지금부터 당신의                   │
│   애착 사물을 깨워볼께요.              │
│                                     │
│   기억을 소환하고 있어요..             │
│                                     │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │      캐릭터 깨우기              │ │
│ └─────────────────────────────────┘ │
│ Home Indicator (34px)               │
└─────────────────────────────────────┘
```

#### Component Specifications

**Navigation Bar**
```yaml
Height: 60px
Background: #FDF7E9
Padding: 16px horizontal

Back Button:
  - Icon: arrow_back_ios
  - Size: 24×24px
  - Color: #333333
  - Position: left-aligned
  - Action: Navigator.pop()

Title:
  - Text: "성격 조제 연금술!"
  - Font: 20px, weight 700
  - Color: #333333
  - Position: center

Skip Button:
  - Text: "건너뛰기"
  - Font: 12px, weight 500
  - Color: #BCBCBC
  - Position: right-aligned
  - Action: Navigator.pushReplacementNamed('/home')
```

**Character Previews**
```yaml
Layout: Horizontal Row
Distribution: Space Evenly
Margin Top: 40px

Character Item:
  - Size: 80×80px
  - Shape: Circle (border-radius: 40px)
  - Border: 2px solid
  - Background: color with 30% opacity
  - Icon: star (40px)
  - Colors: [orange, blue, green]
```

**Main Message**
```yaml
Text: "지금부터 당신의\n애착 사물을 깨워볼께요."
Font: 26px, weight 700, line-height 40px
Color: #333333 (90% opacity)
Alignment: center
Margin Top: 40px
```

**Loading Text**
```yaml
Text: "기억을 소환하고 있어요.."
Font: 14px, weight 400
Color: #BCBCBC
Alignment: center
Margin Top: 20px
```

**CTA Button**
```yaml
Dimensions: 343×56px
Background: #6750A4
Border Radius: 100px
Elevation: 0
Margin: 16px horizontal, 34px bottom

Label:
  - Text: "캐릭터 깨우기"
  - Font: 16px, weight 700
  - Color: white
  - Action: Navigator.pushNamed('/onboarding/input')
```

### **2. 사물 정보 입력 화면 (Figma: 14:3218)**

#### Layout Structure
```
┌─────────────────────────────────────┐
│ Status Bar (44px)                   │
├─────────────────────────────────────┤
│ Navigation Bar (60px)               │
├─────────────────────────────────────┤
│ Title Section (135px)               │
│ 말해줘!                              │
│ 나는 어떤 사물이야?                   │
├─────────────────────────────────────┤
│ Input Section (119px)               │
│ ┌─────────────────────────────────┐ │
│ │ 애칭 [털찐 말랑이________]      │ │
│ │ [우리집 거실 ▼] 에서           │ │
│ │ [3개월 ▼] 정도 함께한          │ │
│ │ [이 빠진 머그컵_____] (이)에요. │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ Error Message (conditional)         │
│ "이름을 입력해주세요!"               │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │           다음                  │ │
│ └─────────────────────────────────┘ │
│ Home Indicator (34px)               │
└─────────────────────────────────────┘
```

#### Input Section Specifications

**Container**
```yaml
Height: 119px
Background: rgba(87, 179, 230, 0.1) // #57B3E6 with 10% opacity
Border Radius: 16px
Padding: 20px
Margin: 16px horizontal
```

**Nickname Field**
```yaml
Layout: Horizontal Row
Spacing: 12px
Margin Bottom: 16px

Label:
  - Text: "애칭"
  - Font: 16px, weight 700
  - Color: #333333

Input Field:
  - Flex: expanded
  - Height: 55px
  - Background: #FFFFFF
  - Border Radius: 40px
  - Padding: 20px horizontal, 16px vertical
  - Placeholder: "털찐 말랑이"
  - Placeholder Color: #B0B0B0
```

**Location Dropdown**
```yaml
Layout: Horizontal Row
Spacing: 8px
Margin Bottom: 16px

Dropdown:
  - Flex: expanded
  - Height: 55px
  - Background: #FFFFFF
  - Border Radius: 40px
  - Padding: 20px horizontal, 16px vertical
  - Options: ["내 방", "우리집 안방", "우리집 거실", "사무실", "단골 카페"]
  - Placeholder: "우리집 거실"

Suffix Text:
  - Text: "에서"
  - Font: 16px, weight 700
  - Color: #333333
```

**Duration Dropdown**
```yaml
# Similar structure to Location Dropdown
Options: ["1개월", "3개월", "6개월", "1년", "2년", "3년 이상"]
Placeholder: "3개월"
Suffix: "정도 함께한"
```

**Object Type Field**
```yaml
# Similar structure to Nickname Field
Placeholder: "이 빠진 머그컵"
Suffix: "(이)에요."
```

#### Error State
```yaml
Display: Conditional (when validation fails)
Position: Below input section
Margin: 20px left

Text:
  - Content: Dynamic based on validation
  - Examples: 
    * "이름을 입력해주세요!"
    * "위치를 선택해주세요!"
    * "함께한 기간을 선택해주세요!"
    * "사물의 종류를 입력해주세요!"
  - Font: 10px, weight 700
  - Color: #FD6262
```

### **3. 드롭다운 열림 상태 (Figma: 14:3303)**

#### Dropdown Menu Specifications
```yaml
Background: #FFFFFF
Border Radius: 5px
Elevation: 2dp (Material Design)
Dimensions: 157×188px
Position: Overlay above input field

Menu Items:
  - Height: 43px each
  - Padding: 16px horizontal
  - Text Alignment: center

Text Style:
  - Font: 16px, weight 400, line-height 24px
  - Color: #333333

States:
  - Normal: Background transparent
  - Selected: Background #DAB7FA
  - Hover: Subtle background highlight
```

---

## 🎯 UX Interaction Patterns

### **Input Flow**
```yaml
Step 1: 애칭 입력
  - User types nickname
  - Real-time validation
  - Remove error state if valid

Step 2: 위치 선택
  - User taps dropdown
  - Show overlay menu
  - Select option
  - Update dropdown display

Step 3: 기간 선택
  - Similar to location selection
  - Update duration display

Step 4: 사물 종류 입력
  - User types object type
  - Real-time validation
  - Remove error state if valid

Step 5: 전체 검증
  - Validate all fields
  - Enable/disable submit button
  - Show appropriate error messages

Step 6: 제출
  - Create UserInput object
  - Navigate to generation screen
  - Pass data as arguments
```

### **Validation Rules**
```yaml
Required Fields: All fields must be filled
Real-time Validation: Show errors immediately
Error Priority: First empty field from top to bottom

Error Messages:
  - Empty nickname: "이름을 입력해주세요!"
  - No location: "위치를 선택해주세요!"
  - No duration: "함께한 기간을 선택해주세요!"
  - Empty object type: "사물의 종류를 입력해주세요!"
```

### **State Management**
```yaml
Input Field States:
  - Empty: Show placeholder
  - Focused: Optional border highlight
  - Filled: Show entered text
  - Error: Show error message below

Button States:
  - Enabled: #6750A4 background
  - Disabled: Gray background (to be implemented)
  - Pressed: Darker #6750A4 with ripple

Dropdown States:
  - Closed: Show selected value or placeholder
  - Open: Show menu overlay
  - Selected: Highlight selected item
```

### **Animation Guidelines**
```yaml
Transitions:
  - Screen Changes: 300ms ease-in-out
  - Dropdown Open/Close: 200ms ease-out
  - Error Message Appearance: 150ms fade-in
  - Button Press: 100ms scale + ripple effect

Micro-interactions:
  - Input Focus: Subtle scale (1.02x)
  - Dropdown Open: Slide down animation
  - Error Message: Shake animation (optional)
  - Button Touch: Material ripple effect
  - Character Preview: Subtle floating animation
```

---

## 🛠 Implementation Guidelines

### **Flutter Widget Structure**
```dart
// Recommended widget hierarchy
Scaffold(
  backgroundColor: AppColors.creamBackground,
  body: SafeArea(
    child: Column(
      children: [
        _buildAppBar(),           // 60px height
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildTitle(),     // Dynamic height
                _buildInputSection(), // 119px + padding
                _buildErrorMessage(), // Conditional
                SizedBox(height: 40),
                _buildSubmitButton(), // 56px + margin
              ],
            ),
          ),
        ),
        _buildHomeIndicator(),    // 34px height
      ],
    ),
  ),
)
```

### **Material 3 Components Mapping**
```yaml
Figma Component → Flutter Widget:
  - Filled Button → ElevatedButton
  - Input Field → TextField with OutlineInputBorder
  - Dropdown → DropdownButtonFormField
  - Error Text → Text with error style
  - App Bar → Custom widget (not AppBar)
```

### **Key Implementation Notes**
```yaml
Colors:
  - Use Material 3 ColorScheme
  - Define custom colors in theme extension
  - Apply opacity using Color.withOpacity()

Typography:
  - Use TextTheme with custom font families
  - Define custom text styles for Figma specifications
  - Ensure consistent line heights

Spacing:
  - Use EdgeInsets.symmetric() for consistent padding
  - Define spacing constants
  - Use SizedBox for vertical spacing

State Management:
  - Use StatefulWidget for form state
  - Implement real-time validation
  - Use TextEditingController for input fields
```

---

## ♿ Accessibility

### **Touch Targets**
```yaml
Minimum Size: 44×44px (iOS) / 48×48dp (Android)
Current Implementation:
  - Buttons: 343×56px ✅
  - Dropdown: Full height 55px ✅
  - Back Button: 24×24px ❌ (needs padding)
  - Skip Button: Text only ❌ (needs padding)
```

### **Color Contrast**
```yaml
WCAG AA Compliance (4.5:1 ratio):
  - Text Primary on Cream: ✅
  - Button Text on Purple: ✅
  - Error Text: ✅
  - Placeholder Text: ⚠️ (verify)
```

### **Screen Reader Support**
```yaml
Semantic Labels:
  - Add semanticsLabel to all interactive elements
  - Provide field descriptions for form inputs
  - Include state information (selected, error, etc.)

Focus Management:
  - Logical tab order
  - Focus visibility indicators
  - Announce state changes
```

### **Responsive Design**
```yaml
Screen Size Support:
  - iPhone SE (375×667): Vertical scroll enabled
  - iPhone Standard (390×844): Default layout
  - iPhone Pro Max (428×926): Increased margins

Text Scaling:
  - Support Dynamic Type (iOS)
  - Test with large text sizes
  - Ensure layout doesn't break
```

---

## 📝 File Organization

### **Recommended Folder Structure**
```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   ├── app_dimensions.dart
│   │   └── app_strings.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   └── onboarding/
│       ├── presentation/
│       │   ├── screens/
│       │   └── widgets/
│       └── domain/
│           └── entities/
└── shared/
    └── widgets/
```

---

## 🔄 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-12-19 | Initial UX/UI guide based on Figma analysis |

---

**Contributors**: Flutter Development Team  
**Review Status**: ✅ Design Review Complete  
**Implementation Status**: 🚧 In Progress 