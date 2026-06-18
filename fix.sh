#!/bin/bash
# 1. Membuat semua struktur folder
mkdir -p lib/core/constants lib/core/theme \
lib/data/models lib/data/repositories \
lib/presentation/providers \
lib/presentation/screens/auth lib/presentation/screens/home

# 2. Membuat file-file yang dibutuhkan (file main.dart biasanya sudah ada bawaan Flutter)
touch lib/core/theme/app_theme.dart \
lib/data/repositories/auth_repository.dart \
lib/presentation/providers/auth_provider.dart \
lib/presentation/screens/auth/auth_screen.dart \
lib/presentation/screens/home/home_screen.dart
echo "Struktur direktori dan import berhasil diperbaiki!"