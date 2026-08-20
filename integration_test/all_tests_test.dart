import 'eticket_cases.dart' as eticket;
import 'gift_tab_cases.dart' as gift_tab;
import 'home_mobileorder_tab_cases.dart' as home_mobileorder;
import 'inbox_cases.dart' as inbox;
import 'login_flow_cases.dart' as login_flow;
import 'pay_tab_cases.dart' as pay_tab;
import 'rewards_screen_cases.dart' as rewards_screen;
import 'setting_screen_cases.dart' as setting_screen;
import 'store_map_tab_cases.dart' as store_map_tab;

void main() {
  login_flow.main();
  pay_tab.main();
  home_mobileorder.main();
  store_map_tab.main();
  gift_tab.main();
  eticket.main();
  inbox.main();
  rewards_screen.main();
  setting_screen.main();
}
