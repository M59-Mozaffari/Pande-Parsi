import 'package:pande_parsi/models/pand.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './local_dtb.dart';

class SupabaseDtb {
  //database to Pand
  final database = Supabase.instance.client.from('persionpand');
  final LocalDtb localDtb = LocalDtb.instance;

  Future<void> fullSync() async {
    try {
      final data = await database.select();

      final List<Pand> serverPands = data.map((e) => Pand.fromMap(e)).toList();

      final localPands = await localDtb.getAllPands();

      // 🔥 ساخت Map برای حذف صدها Query اضافی
      final Map<int, Pand> localPandMap = {
        for (final pand in localPands)
          if (pand.id != null) pand.id!: pand,
      };

      final serverIds = serverPands.map((e) => e.id).toSet();
      final localIds = localPands.map((e) => e.id).toSet();

      /// حذف آیتم‌هایی که در سرور نیستند
      final idsToDelete = localIds.difference(serverIds);

      for (final id in idsToDelete) {
        await localDtb.deletePand(id!);
      }

      /// Insert / Update
      for (final pand in serverPands) {
        final existing = localPandMap[pand.id];

        if (existing == null) {
          await localDtb.insertPand(pand);
        } else {
          pand.isFavorite = existing.isFavorite;
          await localDtb.updatePand(pand);
        }
      }
    } catch (e) {
      print('Full sync error: $e');
    }
  }

  //create
  Future<int?> createPand(Pand newPND) async {
    try {
      final response =
          await database.insert(newPND.toMapForSupabase()).select().single();

      final pand = Pand.fromMap(response);
      await localDtb.insertPand(pand);

      return pand.id;
    } catch (e) {
      print('Error creating pand: $e');
      return null;
    }
  }

  Stream<List<Pand>> get stream {
    return Supabase.instance.client
        .from('persionpand')
        .stream(primaryKey: ['id'])
        .asyncMap((data) async {
          final serverPands = data.map((e) => Pand.fromMap(e)).toList();

          final localPands = await localDtb.getAllPands();

          // 🔥 ساخت Map
          final Map<int, Pand> localPandMap = {
            for (final pand in localPands)
              if (pand.id != null) pand.id!: pand,
          };

          final serverIds = serverPands.map((e) => e.id).toSet();
          final localIds = localPands.map((e) => e.id).toSet();

          /// حذف
          final idsToDelete = localIds.difference(serverIds);

          for (final id in idsToDelete) {
            await localDtb.deletePand(id!);
          }

          /// Insert / Update
          for (final pand in serverPands) {
            final existing = localPandMap[pand.id];

            if (existing == null) {
              await localDtb.insertPand(pand);
            } else {
              pand.isFavorite = existing.isFavorite;
              await localDtb.updatePand(pand);
            }
          }

          return await localDtb.getAllPands();
        });
  }

  Future<int?> updatePand(
    Pand oldPnd,
    String newSentence,
    String newTitle,
    String newTeller,
    Category newCtg,
  ) async {
    try {
      final response =
          await database
              .update({
                'sentence': newSentence,
                'title': newTitle,
                'teller': newTeller,
                'category': newCtg.name,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', oldPnd.id!)
              .select()
              .single();

      final pand = Pand.fromMap(response);
      await localDtb.updatePand(pand);

      return pand.id;
    } catch (e) {
      print('Error updating pand: $e');
      return null;
    }
  }

  Future deletePand(Pand pnd) async {
    try {
      await database.delete().eq('id', pnd.id!);
      await localDtb.deletePand(pnd.id!);
    } catch (e) {
      print('Error deleting $e');
    }
  }

  Future<bool> verifyAccessCode(String userEnteredCode) async {
    final supabaseC = Supabase.instance.client;
    try {
      final response =
          await supabaseC
              .from('access_codes')
              .select()
              .eq('code', userEnteredCode)
              .eq('is_active', true)
              .maybeSingle();
      return response != null;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        return false;
      }
      rethrow;
    }
  }
}
