import mindwave

MW_TIMER = 1000

type mindstate = (int, int)

/** MindWave **/

client function level_to_prefix(level) {
  if (level <= 33) "med"
  else if (level <= 66) "att"
  else "blnk"
}

client function mindwave_to_html(mindwave) {
  match (mindwave) {
  case {none}: <span class="ns-icon32 misc"/>
  case {some:(t, r)}:
    preT = "{level_to_prefix(t)}Face"
    preR = "{level_to_prefix(r)}Glow"
    <span class="ns-icon32 {preR}"><span class="ns-icon32 {preT}"/></span>
  }
}

client @async function update_mindwaves(user_minds) {
  List.iter(function((id, state)) {
    #{"{id}-state"} = mindwave_to_html(state)
  }, user_minds)
}

client reference(option(mindstate)) mindstate =
  ClientReference.create(none)

client function mind_changed(new_state) {
  match (ClientReference.get(mindstate)) {
  case {none}: Option.is_some(new_state)
  case {some:(t, r)}:
    match (new_state) {
    case {none}: true
    case {some:(thinking, relaxation)}:
      thinking <= 33 && t > 33 ||
      thinking <= 66 && (t > 66 || t <= 33) ||
      thinking > 66 && t <= 66 ||
      relaxation <= 33 && r > 33 ||
      relaxation <= 66 && (r > 66 || r <= 33) ||
      relaxation > 66 && r <= 66
    }
  }
}

client function check_mindstate(user) {
  new_mindstate =
    if (MindWave.is_present()) {
      thinking = MindWave.get_thinking_level()
      relaxation = MindWave.get_relaxation_level()
      Log.info("MindWave", "thinking:{thinking} - relaxation:{relaxation}")
      some((thinking, relaxation))
    } else none
  if (mind_changed(new_mindstate)) {
    user = { user with mindwave:new_mindstate }
    Network.broadcast({mindstate:user}, room)
  }
  ClientReference.set(mindstate, new_mindstate)
}

// Init various scheduling tasks
client function init_scheduling(user, _) {
  Scheduler.timer(MW_TIMER, function(){
    check_mindstate(user)
  })
}

server mindwave_flash =
  <div id="flashContent">
    <object classid="clsid:d27cdb6e-ae6d-11cf-96b8-444553540000" width="220" height="40" id="FlashToJs" align="middle">
      <param name="movie" value="/resources/neurosky/FlashToJs/FlashToJs.swf" />
      <param name="quality" value="high" />
      <param name="bgcolor" value="#ffffff" />
      <param name="play" value="true" />
      <param name="loop" value="true" />
      <param name="wmode" value="window" />
      <param name="scale" value="showall" />
      <param name="menu" value="true" />
      <param name="devicefont" value="false" />
      <param name="salign" value="" />
      <param name="allowScriptAccess" value="sameDomain" />
      {Xhtml.of_string_unsafe("<!--[if !IE]>-->")}
      <object type="application/x-shockwave-flash" data="/resources/neurosky/FlashToJs/FlashToJs.swf" width="220" height="40">
        <param name="movie" value="/resources/neurosky/FlashToJs/FlashToJs.swf" />
        <param name="quality" value="high" />
        <param name="bgcolor" value="#ffffff" />
        <param name="play" value="true" />
        <param name="loop" value="true" />
        <param name="wmode" value="window" />
        <param name="scale" value="showall" />
        <param name="menu" value="true" />
        <param name="devicefont" value="false" />
        <param name="salign" value="" />
        <param name="allowScriptAccess" value="sameDomain" />
      {Xhtml.of_string_unsafe("<!--<![endif]-->")}
        <a href="http://www.adobe.com/go/getflash">
                <img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Get Adobe Flash player" />
        </a>
      {Xhtml.of_string_unsafe("<!--[if !IE]>-->")}
      </object>
      {Xhtml.of_string_unsafe("<!--<![endif]-->")}
    </object>
  </div>


