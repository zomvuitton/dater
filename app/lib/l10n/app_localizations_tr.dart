// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Dater';

  @override
  String get appTagline => 'Boş saatlerini seçtiğin çevrelerle paylaş.';

  @override
  String get navMyWeek => 'Takvimim';

  @override
  String get navCircles => 'Çevreler';

  @override
  String get navFriends => 'Arkadaşlar';

  @override
  String get navProfile => 'Profil';

  @override
  String get cancel => 'Vazgeç';

  @override
  String get save => 'Kaydet';

  @override
  String get delete => 'Sil';

  @override
  String get remove => 'Çıkar';

  @override
  String get retry => 'Tekrar dene';

  @override
  String get join => 'Katıl';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get errorGeneric => 'Bir şeyler ters gitti. Lütfen tekrar dene.';

  @override
  String get fieldRequired => 'Zorunlu alan';

  @override
  String get email => 'E-posta';

  @override
  String get emailInvalid => 'Geçerli bir e-posta adresi gir';

  @override
  String get password => 'Şifre';

  @override
  String get passwordTooShort => 'En az 6 karakter';

  @override
  String get signIn => 'Giriş yap';

  @override
  String get signUp => 'Hesap oluştur';

  @override
  String get signOut => 'Çıkış yap';

  @override
  String get haveAccount => 'Hesabın var mı? Giriş yap';

  @override
  String get noAccount => 'Yeni misin? Hesap oluştur';

  @override
  String get authCheckEmail => 'Hesabını onaylamak için e-postanı kontrol et, sonra giriş yap.';

  @override
  String get displayName => 'İsim';

  @override
  String get username => 'Kullanıcı adı';

  @override
  String get usernameHelp => '3–20 karakter: a–z, 0–9 ve _';

  @override
  String get usernameInvalid => '3–20 küçük harf, rakam veya _ kullan';

  @override
  String get usernameTaken => 'Bu kullanıcı adı alınmış';

  @override
  String get onboardingTitle => 'Kullanıcı adını seç';

  @override
  String get onboardingBody => 'Arkadaşların seni @kullanıcıadın ile bulup ekler.';

  @override
  String get continueAction => 'Devam';

  @override
  String get myWeekTitle => 'Takvimim';

  @override
  String get myWeekHint => 'Saatlere dokunarak seç ya da basılı tutup sürükle. Tüm günü seçmek için güne dokun.';

  @override
  String hoursSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat seçildi',
      one: '1 saat seçildi',
    );
    return '$_temp0';
  }

  @override
  String get clearSelection => 'Seçimi temizle';

  @override
  String get markAvailable => 'Müsaitim';

  @override
  String get removeAvailability => 'Müsaitliği kaldır';

  @override
  String sharedHours(int hours, int circles) {
    return '$hours saat $circles çevreyle paylaşıldı';
  }

  @override
  String removedHours(int count) {
    return '$count saat kaldırıldı';
  }

  @override
  String get copyPreviousWeek => 'Geçen haftayı kopyala';

  @override
  String get copyWeekTitle => 'Geçen hafta kopyalansın mı?';

  @override
  String get copyWeekBody => 'Bu haftaki müsaitliğin geçen haftanınkiyle değiştirilecek.';

  @override
  String get copyWeekAction => 'Kopyala';

  @override
  String copyWeekDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saat kopyalandı',
      zero: 'Geçen hafta boştu',
    );
    return '$_temp0';
  }

  @override
  String get noCirclesTitle => 'Önce bir çevre oluştur';

  @override
  String get noCirclesBody =>
      'Her boş saati hangi çevrelerin göreceğini sen seçersin; bunun için en az bir çevren olmalı.';

  @override
  String get pickerTitle => 'Kimler görebilsin?';

  @override
  String pickerSubtitle(int count) {
    return '$count boş saati şu çevrelerle paylaş:';
  }

  @override
  String get pickerAllCircles => 'Tüm çevreler';

  @override
  String get pickerSave => 'Paylaş';

  @override
  String get newCircle => 'Yeni çevre';

  @override
  String get editCircle => 'Çevreyi düzenle';

  @override
  String get createCircle => 'Çevre oluştur';

  @override
  String get circleName => 'Ad';

  @override
  String get circleNameHint => 'ör. Yakın arkadaşlar, Tırmanış, İş';

  @override
  String get circleIcon => 'Simge';

  @override
  String get circleColor => 'Renk';

  @override
  String get circlesEmptyTitle => 'Henüz çevren yok';

  @override
  String get circlesEmptyBody => 'Bir arkadaş grubu için çevre oluştur ya da davet koduyla birine katıl.';

  @override
  String memberCount(int count) {
    return '$count üye';
  }

  @override
  String get youOwn => 'Senin';

  @override
  String get owner => 'Sahibi';

  @override
  String youSuffix(String name) {
    return '$name (sen)';
  }

  @override
  String get joinWithCode => 'Kodla katıl';

  @override
  String get inviteCode => 'Davet kodu';

  @override
  String get inviteInvalid => 'Bu davet kodu artık geçerli değil.';

  @override
  String get backToCircles => 'Çevrelere dön';

  @override
  String get invite => 'Davet et';

  @override
  String inviteTitle(String name) {
    return '$name çevresine davet et';
  }

  @override
  String get inviteBody => 'Bu kod veya linke sahip herkes çevreye katılabilir.';

  @override
  String get copyCode => 'Kodu kopyala';

  @override
  String get shareLink => 'Linki paylaş';

  @override
  String inviteShareText(String name, String link, String code) {
    return 'Dater\'da \"$name\" çevreme katıl: $link (kod: $code)';
  }

  @override
  String get inviteWithLink => 'Linkle davet et';

  @override
  String get inviteWithLinkBody => 'Davet kodunu dilediğinle paylaş';

  @override
  String get addFriendToCircle => 'Arkadaş ekle';

  @override
  String get noFriendsToAdd => 'Tüm arkadaşların zaten bu çevrede.';

  @override
  String removeMemberTitle(String name) {
    return '$name çevreden çıkarılsın mı?';
  }

  @override
  String get regenerateCode => 'Yeni davet kodu';

  @override
  String get regenerateCodeTitle => 'Yeni davet kodu oluşturulsun mu?';

  @override
  String get regenerateCodeBody => 'Eski kod ve linkler artık çalışmayacak.';

  @override
  String get leaveCircle => 'Çevreden ayrıl';

  @override
  String leaveCircleTitle(String name) {
    return '$name çevresinden ayrılıyor musun?';
  }

  @override
  String get leaveCircleBody => 'Bu çevreyle paylaştığın saatler kaldırılacak.';

  @override
  String get deleteCircle => 'Çevreyi sil';

  @override
  String deleteCircleTitle(String name) {
    return '$name silinsin mi?';
  }

  @override
  String get deleteCircleBody => 'Bu çevrenin üyelikleri, paylaşılan saatleri ve planları silinecek.';

  @override
  String get tabWeek => 'Boş saatler';

  @override
  String get tabPlans => 'Planlar';

  @override
  String get tabMembers => 'Üyeler';

  @override
  String get heatmapHint =>
      'Sayılar kaç üyenin boş olduğunu gösterir. Kimlerin boş olduğunu görmek ve plan önermek için saate dokun.';

  @override
  String freeCount(int free, int total) {
    return '$total kişiden $free kişi boş';
  }

  @override
  String get nobodyFree => 'Bu saati henüz kimse paylaşmadı.';

  @override
  String get proposePlan => 'Plan öner';

  @override
  String get proposePlanAction => 'Öner';

  @override
  String get planTitle => 'Plan ne?';

  @override
  String get planTitleHint => 'ör. Kahve, Film gecesi';

  @override
  String get planNote => 'Not (isteğe bağlı)';

  @override
  String get startTime => 'Başlangıç saati';

  @override
  String get endTime => 'Bitiş saati';

  @override
  String get plansEmptyTitle => 'Henüz plan yok';

  @override
  String get plansEmptyBody => 'Plan önermek için Boş saatler sekmesinde bir saate dokun.';

  @override
  String proposedBy(String name) {
    return '$name önerdi';
  }

  @override
  String planCounts(int going, int maybe, int no) {
    return '$going geliyor · $maybe belki · $no gelemiyor';
  }

  @override
  String get going => 'Geliyorum';

  @override
  String get maybe => 'Belki';

  @override
  String get notGoing => 'Gelemem';

  @override
  String get deletePlanTitle => 'Bu plan silinsin mi?';

  @override
  String get searchUsername => '@kullanıcıadı ile ara';

  @override
  String get noUsersFound => 'Kullanıcı bulunamadı';

  @override
  String get addFriend => 'Ekle';

  @override
  String get accept => 'Kabul et';

  @override
  String get decline => 'Reddet';

  @override
  String get requestSent => 'Arkadaşlık isteği gönderildi';

  @override
  String get requestPending => 'Bekliyor';

  @override
  String get friendsLabel => 'Arkadaşsınız';

  @override
  String get incomingRequests => 'Arkadaşlık istekleri';

  @override
  String get sentRequests => 'Gönderilen istekler';

  @override
  String get cancelRequest => 'Geri çek';

  @override
  String friendsCount(int count) {
    return 'Arkadaşlar ($count)';
  }

  @override
  String get friendsEmpty => 'Yukarıdan kullanıcı adıyla arkadaşlarını ara.';

  @override
  String get unfriend => 'Arkadaşlıktan çıkar';

  @override
  String unfriendTitle(String name) {
    return '$name arkadaşlıktan çıkarılsın mı?';
  }

  @override
  String get unfriendBody => 'Zaten ortak olduğunuz çevrelerde kalmaya devam edersiniz.';

  @override
  String get language => 'Dil';

  @override
  String get languageSystem => 'Cihaz dili';

  @override
  String get open => 'Aç';

  @override
  String get notificationsTitle => 'Bildirimler';

  @override
  String get markAllRead => 'Tümünü okundu say';

  @override
  String get notificationsEmptyTitle => 'Henüz bildirim yok';

  @override
  String get notificationsEmptyBody => 'Çevrelerindeki yeni planlar ve planlarına gelen yanıtlar burada görünür.';

  @override
  String notifPlanProposed(String name, String title) {
    return '$name yeni bir plan önerdi: $title';
  }

  @override
  String notifPlanGoing(String name, String title) {
    return '$name “$title” planına geliyor';
  }

  @override
  String notifPlanMaybe(String name, String title) {
    return '$name “$title” planı için “belki” dedi';
  }

  @override
  String notifPlanNo(String name, String title) {
    return '$name “$title” planına gelemiyor';
  }

  @override
  String get timeJustNow => 'şimdi';

  @override
  String timeMinutesAgo(int count) {
    return '$count dk önce';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count sa önce';
  }
}
