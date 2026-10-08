enum ActorRole { munfarid, imam, muqtadi, masbuq, lahiq }

extension ActorRoleLabel on ActorRole {
  String get label {
    switch (this) {
      case ActorRole.munfarid: return 'Munfarid';
      case ActorRole.imam: return 'Imom';
      case ActorRole.muqtadi: return 'Muqtadi';
      case ActorRole.masbuq: return 'Masbuq';
      case ActorRole.lahiq: return 'Lahiq';
    }
  }
}
