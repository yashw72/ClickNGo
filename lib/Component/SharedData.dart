class SharedData {
  static  final SharedData _instance = SharedData._internal();

  factory SharedData() {
    return _instance;
  }

  SharedData._internal();

   String ademail='';
   String? organizationname='';

  void setadminEmail(String newEmail){
    ademail = newEmail;
  }
  void setorgname(String? neworg){
    organizationname = neworg;
  }
}
