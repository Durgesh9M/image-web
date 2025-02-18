// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:ui_web' as ui; // Updated import for Flutter Web
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:js/js.dart';
// Import dart:html only when on Web.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// JS interop for fullscreen toggling.
/// These functions call the JavaScript functions defined in web/index.html.
@JS('requestFullscreen')
external Future<void> requestFullscreenJS();

@JS('exitFullscreen')
external Future<void> exitFullscreenJS();

/// Enters fullscreen mode using JS interop.
Future<void> _enterFullscreen() async {
  await requestFullscreenJS();
}

/// Exits fullscreen mode using JS interop.
Future<void> _exitFullscreen() async {
  await exitFullscreenJS();
}

/// The entry point of the application.
void main() {
  runApp(const MyApp());
}

/// Main application widget.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: const HomePage(),
    );
  }
}

/// HomePage displays a URL input, an HTML image (via HtmlElementView),
/// and a floating plus button with a context menu for fullscreen actions.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State for HomePage.
class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  String _imageUrl = '';
  bool _showContextMenu = false;
  bool _isFullscreen = false;

  /// The HTML image element to display the image.
  late final html.ImageElement _imgElement;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Create and configure the HTML image element.
      _imgElement = html.ImageElement()
        ..style.borderRadius = '12px'
        ..style.objectFit = 'cover'
        ..style.width = '100%'
        ..style.height = '100%';

      // Register the view factory using ui.platformViewRegistry from dart:ui_web.
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'html-image-view',
        (int viewId) => _imgElement,
      );

      // Add a double-click listener to toggle fullscreen.
      _imgElement.onDoubleClick.listen((event) {
        if (_isFullscreen) {
          _exitFullscreen().then((_) {
            setState(() {
              _isFullscreen = false;
            });
          });
        } else {
          _enterFullscreen().then((_) {
            setState(() {
              _isFullscreen = true;
            });
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  /// Toggles the visibility of the context menu.
  void _toggleContextMenu() {
    setState(() {
      _showContextMenu = !_showContextMenu;
    });
  }

  /// Hides the context menu.
  void _hideContextMenu() {
    if (_showContextMenu) {
      setState(() {
        _showContextMenu = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use GestureDetector to hide context menu when tapping outside.
      body: GestureDetector(
        onTap: _hideContextMenu,
        child: Stack(
          children: [
            // Main content: URL input and image display.
            Column(
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          decoration: const InputDecoration(
                            hintText: 'Enter Image URL',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _imageUrl = value.trim();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (_imageUrl.isNotEmpty) {
                              _imgElement.src = _imageUrl;
                            }
                          });
                        },
                        child: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: _imageUrl.isNotEmpty
                        ? SizedBox(
                            width: 300,
                            height: 300,
                            child: const HtmlImageView(),
                          )
                        : const Text('Enter an image URL to display'),
                  ),
                ),
              ],
            ),
            // Dimming overlay, positioned above main content.
            if (_showContextMenu)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _hideContextMenu,
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
            // Floating plus button and context menu, positioned at bottom-right.
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Context menu appears above the plus button.
                  if (_showContextMenu)
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: () {
                              // Enter fullscreen action.
                              _enterFullscreen().then((_) {
                                setState(() {
                                  _isFullscreen = true;
                                });
                              });
                              _hideContextMenu();
                            },
                            child: const Text('Enter fullscreen'),
                          ),
                          TextButton(
                            onPressed: () {
                              // Exit fullscreen action.
                              _exitFullscreen().then((_) {
                                setState(() {
                                  _isFullscreen = false;
                                });
                              });
                              _hideContextMenu();
                            },
                            child: const Text('Exit fullscreen'),
                          ),
                        ],
                      ),
                    ),
                  FloatingActionButton(
                    onPressed: _toggleContextMenu,
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A widget that displays the registered HTML image element using HtmlElementView.
class HtmlImageView extends StatelessWidget {
  const HtmlImageView({super.key});

  @override
  Widget build(BuildContext context) {
    return kIsWeb
        ? HtmlElementView(viewType: 'html-image-view')
        : const SizedBox.shrink();
  }
}
