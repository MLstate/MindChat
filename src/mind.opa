import mindwave

MW_TIMER = 1000

type mindstate = (int, int)

/** MindWave **/

client function mindwave_to_html(mindwave) {
  match (mindwave) {
  case {none}: <span class="ns-icon32 misc"/>
  case {some:(a, m)}:
    ao = Int.to_float(a) / 100.
    mo = Int.to_float(m) / 100.
    <span class="ns-icon32 attFace">
      <span class="ns-icon32 attGlow"
            style="opacity:{ao}; filter:alpha(opacity={a});"/>
    </span>
    <span class="ns-icon32 medFace">
      <span class="ns-icon32 medGlow"
            style="opacity:{mo}; filter:alpha(opacity={m});"/>
    </span>
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
    case {none}: (t > 0 || r > 0)
    case {some:(attention, meditation)}:
      Int.abs(attention - t) > 10
      || Int.abs(meditation - r) > 10
      // attention <= 33 && t > 33 ||
      // attention <= 66 && (t > 66 || t <= 33) ||
      // attention > 66 && t <= 66 ||
      // meditation <= 33 && r > 33 ||
      // meditation <= 66 && (r > 66 || r <= 33) ||
      // meditation > 66 && r <= 66
    }
  }
}

client function check_mindstate(user) {
  new_mindstate =
    if (MindWave.is_present()) {
      attention = MindWave.get_attention_level()
      meditation = MindWave.get_meditation_level()
      Log.info("MindWave", "attention:{attention} - meditation:{meditation}")
      some((attention, meditation))
    } else none
  if (mind_changed(new_mindstate)) {
    user = { user with mindwave:new_mindstate }
    Network.broadcast({mindstate:user}, room)
  }
  ClientReference.set(mindstate, new_mindstate)
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


