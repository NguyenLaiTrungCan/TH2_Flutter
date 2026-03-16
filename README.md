# todo_list

A new Flutter project.

## Supabase Storage setup

App dang dung Firebase cho Auth + Firestore, va Supabase de luu anh/video.

1. Tao project tren Supabase.
2. Vao `Storage` -> tao bucket `note-media` (hoac ten khac).
3. Dat bucket o che do `Public` de app co the hien thi URL truc tiep.
4. Lay `Project URL` va `anon public key` trong `Project Settings`.

### Storage policy (de upload thanh cong)

Vi app hien tai dang dang nhap bang Firebase (khong phai Supabase Auth), request upload se di voi role `anon`.
Ban can tao policy cho `storage.objects` (demo/dev):

```sql
create policy "Public read note media"
on storage.objects
for select
to public
using (bucket_id = 'note-media');

create policy "Anon upload note media"
on storage.objects
for insert
to anon
with check (bucket_id = 'note-media');
```

Neu bucket cua ban khong phai `note-media`, thay ten bucket trong policy.
Production nen upload qua backend hoac signed upload URL de an toan hon.

Hien tai project da nhung san `SUPABASE_URL` va `SUPABASE_ANON_KEY` trong code,
nen co the chay truc tiep:

```bash
flutter run -d <device-id>
```

Neu can doi project Supabase ma khong sua code, co the override bang dart-define:

```bash
flutter run \
	--dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
	--dart-define=SUPABASE_BUCKET=note-media
```

Neu khong truyen `SUPABASE_BUCKET`, app mac dinh dung `note-media`.
