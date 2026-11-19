import 'package:flutter/material.dart';

/// Isi halaman yang bisa di-scroll, rata tengah dengan lebar maksimal.
/// [center] = true memusatkan isi secara vertikal juga (untuk form pendek).
class PageBody extends StatelessWidget {
  const PageBody({
    super.key,
    required this.children,
    this.maxWidth = 420,
    this.center = false,
  });

  final List<Widget> children;
  final double maxWidth;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final scroll = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );

    return SafeArea(
      child: center
          ? Center(child: scroll)
          : Align(alignment: Alignment.topCenter, child: scroll),
    );
  }
}
