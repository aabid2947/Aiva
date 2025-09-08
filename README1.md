
# **Project Name**

[![React Native](https://img.shields.io/badge/React%20Native-v0.75.2-blue)](https://reactnative.dev/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## **Table of Contents**

- [Introduction](#introduction)
- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Components](#components)
- [Contributing](#contributing)
- [License](#license)

---

## **Introduction**

`Project Name` is a React Native application designed to provide [describe the functionality of the app]. It uses modern React Native architecture, custom components, and optimized styling practices for a seamless user experience.

---

## **Features**

- **Custom Cards**: Reusable card components like `StatusDetailCard` and `TodayActivityCard`.
- **Dynamic Content**: Editable and non-editable content handled efficiently.
- **Responsive Design**: Components adapt to different screen sizes.
- **Custom Styling**: Modular and maintainable styles.
- **Interactive UI**: Includes elements like buttons, inputs, and icons.

---

## **Installation**

Follow these steps to set up the project locally:

1. Clone the repository:
   ```bash
   git clone https://github.com/your-repo/project-name.git
   cd project-name
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run the app:
   ```bash
   npx react-native run-android # For Android
   npx react-native run-ios     # For iOS
   ```

---

## **Usage**

After setting up, you can start the app on your simulator or connected device. Navigate through the app to explore features like:

- Viewing and editing content in cards.
- Testing responsiveness with various device sizes.
- Experimenting with the `onEdit` actions and other interactive elements.

---

## **Project Structure**

```plaintext
src/
├── components/
│   ├── input/
│   │   └── HMTextInput.tsx
│   ├── cards/
│   │   ├── StatusDetailCard.tsx
│   │   └── TodayActivityCard.tsx
│   ├── typography/
│   │   ├── SubtitleMedium.tsx
│   │   └── BodyLarge.tsx
│   └── theme/
│       ├── colors.ts
│       └── styles.ts
├── screens/
│   ├── HomeScreen.tsx
│   └── DetailsScreen.tsx
├── App.tsx
└── index.js
```

---

## **Components**

### **1. StatusDetailCard**
A customizable card component that displays a title and list of editable or non-editable items.

#### Props:
- `title`: String - The title of the card.
- `content`: Array - Array of objects with `title` and `quantity`.
- `editable`: Boolean - Enables editing when true.
- `onEdit`: Function - Callback for edit action.
- `components`: ReactNode - Additional elements to render below the card.

### **2. TodayActivityCard**
Displays a small card with an image and text, typically for activity previews.

#### Props:
- `picture`: Image source.
- `title`: String - The text to display on the card.

---

## **Contributing**

Contributions are welcome! Please follow these steps:

1. Fork the repository.
2. Create a new branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. Commit your changes:
   ```bash
   git commit -m "Add some feature"
   ```
4. Push to the branch:
   ```bash
   git push origin feature/your-feature-name
   ```
5. Open a Pull Request.

---

## **License**

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---
