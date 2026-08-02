class PresetAvatar {
  final String id;
  final String label;
  final String assetPath;

  const PresetAvatar({
    required this.id,
    required this.label,
    required this.assetPath,
  });
}

const List<PresetAvatar> presetAvatars = [
  PresetAvatar(id: 'panda', label: 'Panda', assetPath: 'assets/avatars/panda.png'),
  PresetAvatar(id: 'rabbit', label: 'Tavşan', assetPath: 'assets/avatars/rabbit.png'),
  PresetAvatar(id: 'raccoon', label: 'Rakun', assetPath: 'assets/avatars/raccoon.png'),
  PresetAvatar(id: 'owl', label: 'Baykuş', assetPath: 'assets/avatars/owl.png'),
  PresetAvatar(id: 'squirrel', label: 'Sincap', assetPath: 'assets/avatars/squirrel.png'),
  PresetAvatar(id: 'cat', label: 'Kedi', assetPath: 'assets/avatars/cat.png'),
  PresetAvatar(id: 'fox', label: 'Tilki', assetPath: 'assets/avatars/fox.png'),
  PresetAvatar(id: 'bee', label: 'Arı', assetPath: 'assets/avatars/bee.png'),
];
