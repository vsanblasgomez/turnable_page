# Turnable Page

A Flutter package that provides a realistic page-flipping effect for digital books, magazines, catalogs, and other multi-page content in Flutter applications.

## v1.0.0


### ✨ What's New

* ✅ **Interactive Content**: Buttons, inputs, and other widgets inside pages are now fully functional and respond to user interactions.
* 🌟 **Smart Gesture Detection**: Automatically distinguishes between widget interaction and page-flip gestures, preventing accidental flips.
* ⚡ **Improved Performance**: Migrated from `CustomPainter` to Flutter's native `RenderBox` system for smoother animations and faster rendering.
* 🔍 **Zoom Support**: Smooth zoom in/out functionality for improved readability and content inspection. Any ongoing page-flip animation is automatically **canceled** when zoom is activated to prevent state conflicts and visual glitches.
* 🌗 **Customizable Center Shadow**: Adjustable gutter shadow between pages, allowing precise control over depth intensity and enhancing the realistic book effect.
* 📖 **Pages-Only Mode**: When `PaperBoundaryDecoration` is set to `none`, the outer book structure (cover and boundary decoration) is removed, rendering only the inner pages for a cleaner and more minimal layout.


## Features

✅ **Realistic Physics**: Advanced flip animations with proper physics and shadows
✅ **Zoom Support**: Smooth zoom in/out functionality for improved readability and content inspection. Automatically cancels any ongoing page-flip animation when activated to prevent state conflicts and visual glitches.
✅ **Interactive Content**: Full support for interactive widgets (buttons, inputs, etc.) within pages  
✅ **Smart Gestures**: Automatic differentiation between drag (page flip) and tap (widget interaction)  
✅ **Touch Support**: Full touch and gesture support for mobile devices  
✅ **Multiple Orientations**: Automatic portrait/landscape orientation handling  
✅ **Widget Support**: Use any Flutter widget as page content with full interactivity  
✅ **Customizable**: Extensive configuration options for gestures and animations  
✅ **Performance**: Hardware-accelerated rendering using Flutter's native RenderBox system  
✅ **Events**: Rich event system for interaction handling  
✅ **Responsive**: Auto-sizing and responsive layout support  
✅ **Cross-Platform**: Supports Mobile, Web, and Windows

> **NEW**: Widgets inside book pages are now fully interactive! The smart gesture system automatically detects when you're interacting with buttons or other widgets vs. when you want to flip pages.

## Demo

### Desktop flipping

![Desktop flipping](https://raw.githubusercontent.com/saeedahmed725/turnable_page/main/demo/desktop-fliping.gif)

### Mobile flipping

![Mobile flipping](https://raw.githubusercontent.com/saeedahmed725/turnable_page/main/demo/mobile-fliping.gif)

### Responsiveness

![Responsiveness](https://raw.githubusercontent.com/saeedahmed725/turnable_page/main/demo/responsiveness.gif)

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  git:
    url: https://github.com/vsanblasgomez/turnable_page.git
    ref: v1.0.0
```

Then run:

```bash
flutter pub get
```

## Basic Usage

### Simple Widget-Based Book

```dart
import 'package:flutter/material.dart';
import 'package:turnable_page/turnable_page.dart';

class MyBook extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TurnablePage(
            pageCount: 6,
            pageBuilder: (index, constraints) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                ),
                child: Center(
                  child: Text(
                    'Page ${index + 1}',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              );
            },
          ),
      ),
    );
  }
}
```

### Page Flip Controller

Controller class for programmatic page manipulation.

#### Methods

- `nextPage()` - Turn to the next page (without animation)
- `previousPage()` - Turn to the previous page (without animation)
- `goToPage(int pageIndex)` - Jump to a specific page (without animation)
- `flipNext([FlipCorner corner])` - Flip to next page with animation
- `flipPrev([FlipCorner corner])` - Flip to previous page with animation
- `flipToPage(int pageIndex, [FlipCorner corner])` - Flip to specific page with animation

#### Properties

- `currentPageIndex` - Get current page index (0-based)
- `pageCount` - Get total number of pages
- `hasNextPage` - Check if next page is available
- `hasPreviousPage` - Check if previous page is available
- `canFlipNext` - Check if can flip to next page
- `canFlipPrev` - Check if can flip to previous page


### Usage

```dart
PageFlipController _controller = PageFlipController;

_controller.previousPage();
_controller.nextPage();
_controller.goToPage(5);
_controller.flipPrev();
_controller.flipNext();
_controller.flipToPage(5);

_controller.hasPreviousPage;
_controller.hasNextPage;

```


## Gesture Behavior

Page flip initiation is simplified: users flip pages by dragging or tapping near a page corner. Interactions on widgets (buttons, etc.) inside a page are still delivered to those widgets; a flip starts only when the gesture originates in a corner region or becomes a drag exceeding the movement threshold.

Key tunables that remain:
```dart
FlipSettings(
  cornerTriggerAreaSize: 0.15, // fraction of page diagonal for active corners
  swipeDistance: 80.0,         // drag distance threshold
)
```
Removed flags: enableSmartGestures, disableFlipByClick, clickEventForward (behavior now automatic and consistent).


#### Parameters

- `controller` - Optional controller for programmatic page control
- `itemBuilder` - Builder function that creates widget content for each page
- `itemCount` - Total number of pages in the book
- `onPageChanged` - Callback fired when page changes
- `pageViewMode` - Display mode: single page or double page spread
- `pixelRatio` - Rendering pixel ratio for quality
- `autoResponseSize` - Whether to automatically adjust size to container
- `aspectRatio` - Custom aspect ratio for the book
- `paperBoundaryDecoration` - Visual style for page boundaries
- `settings` - Detailed flip behavior configuration



### FlipSettings Configuration

Configuration object for customizing flip behavior and appearance.

#### Constructor Parameters

| Parameter             | Type       | Default          | Description                                                |
| --------------------- | ---------- | ---------------- | ---------------------------------------------------------- |
| `startPageIndex`      | `int`      | `0`              | Initial page to display (0-based index)                    |
| `size`                | `SizeType` | `SizeType.fixed` | Size calculation: fixed dimensions or stretch to fit       |
| `width`               | `double`   | `0`              | Width of the book in pixels                                |
| `height`              | `double`   | `0`              | Height of the book in pixels                               |
| `drawShadow`          | `bool`     | `true`           | Whether to draw realistic shadow effects                   |
| `flippingTime`        | `int`      | `700`            | Duration of flip animation in milliseconds                 |
| `usePortrait`         | `bool`     | `true`           | Portrait mode (single page) vs landscape (two-page spread) |
| `maxShadowOpacity`    | `double`   | `1.0`            | Maximum opacity for shadow effects (0.0 to 1.0)            |
| `showCover`           | `bool`     | `false`          | Whether the book has a front/back cover                    |
| `mobileScrollSupport` | `bool`     | `true`           | Enable touch scrolling on mobile devices                   |
| `swipeDistance`       | `double`   | `100.0`          | Minimum distance in pixels for swipe gesture               |
| `showPageCorners`     | `bool`     | `true`           | Show interactive corner highlighting on hover              |
| `centerShadowOpacity` | `double`   | `0.5`            | Show the opacity of inner book shadow                      |
| `centerShadowSize`    | `double`   | `0.05`           | Size of inner book shadow                                  |

#### PageViewMode

- `PageViewMode.single` - Single page view (portrait orientation)
- `PageViewMode.double` - Double page spread (landscape orientation)

#### SizeType

- `SizeType.fixed` - Fixed dimensions specified by width/height
- `SizeType.stretch` - Stretch to fit parent container

#### FlipCorner

- `FlipCorner.topLeft` - Flip from top-left corner
- `FlipCorner.topRight` - Flip from top-right corner
- `FlipCorner.bottomLeft` - Flip from bottom-left corner
- `FlipCorner.bottomRight` - Flip from bottom-right corner

#### PaperBoundaryDecoration

- `PaperBoundaryDecoration.vintage` - Vintage paper styling
- `PaperBoundaryDecoration.modern` - Modern clean styling
- `PaperBoundaryDecoration.parchment` - Parchment-style textured paper with warm, aged tones


### Responsive Design

```dart
// Automatic responsive behavior
TurnablePage(
  autoResponseSize: true,      // Adapts to device size only in single mode
  pageViewMode: PageViewMode.single, // Switches based on screen size
  // ...
)
```

### PDF Support (TurnablePdf)

The package includes a helper wrapper `TurnablePdf` for quickly displaying PDF documents with the same flipping experience.

#### Initialization

Call once before runApp (e.g. in `main()`):

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TurnablePdf.initPDFLoaders(); // prepare PDF loaders (network / asset / file)
  runApp(const MyApp());
}
```

#### Basic Network PDF

```dart
TurnablePdf.network(
  'https://example.com/sample.pdf',
  pageViewMode: PageViewMode.double,
  paperBoundaryDecoration: PaperBoundaryDecoration.modern,
  settings: FlipSettings(
    flippingTime: 800,
    swipeDistance: 60,
    cornerTriggerAreaSize: 0.15,
  ),
)
```

#### From Assets

```dart
TurnablePdf.asset(
  'assets/docs/book.pdf',
  pageViewMode: PageViewMode.single,
)
```

#### From File (e.g. file picker)

```dart
final file = File(pathFromPicker);
TurnablePdf.file(
  file,
  pageViewMode: PageViewMode.double,
)
```

#### Custom Page Builder Hook

You can wrap each rendered PDF page (which is provided as an `Image` / `Widget`) inside additional UI by using the standard `builder` of `TurnablePage` in combination with `TurnablePdf` if you expose the underlying controller. (Advanced usage; see source for details.)

#### Notes

- Pages are rasterized; large PDFs may take time to render on first load.

## Roadmap

- [x] Core page flipping logic
- [x] Widget-based pages
- [x] Touch/gesture handling
- [x] Interactive content support
- [x] Smart gesture detection
- [x] Event system and callbacks
- [x] Hardware-accelerated rendering with RenderBox
- [x] Responsive design support
- [x] Portrait/landscape orientation
- [x] PDF document support
- [ ] Enhanced accessibility features
- [ ] Advanced animation customization
- [ ] Bookmark and navigation features




## Contributing

Contributions are welcome! Feel free to open issues and PRs to improve the package.

### Development Setup

1. Clone the repository:

```bash
git clone https://github.com/saeedahmed725/turnable_page.git
cd turnable_page
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the example:

```bash
cd example
flutter run
```

### Guidelines

- Keep the public API stable when possible and document any changes
- Follow Flutter development best practices
- Include tests for new features
- Update documentation for any API changes
- Ensure backward compatibility

## License

This project is distributed under the Turnable Page Proprietary License (TPPL). Usage, redistribution, and modification are not permitted except via approved pull requests in the official GitHub repository. See the [LICENSE](LICENSE) file for full terms.

## Credits

- Built with ❤️ for the Flutter community

## Support

If you find this package helpful, please:

- ⭐ Star the repository on GitHub
- 🐛 Report issues on GitHub Issues
- 💡 Suggest features and improvements
- 📖 Contribute to documentation

For support and questions, please use GitHub Issues or start a discussion in the repository.
