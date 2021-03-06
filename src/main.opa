/*  A simple, one-room, scalable real-time web chat, with file sharing

    Copyright © 2010-2012 MLstate

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/**
 * @author David Rajchenbach-Teller
 * @author Henri Binsztok
 * @author Frederic Ye
 */

import stdlib.system
import stdlib.themes.bootstrap

/** Constants **/

GITHUB_USER = "MLstate"
GITHUB_REPO = "MindChat"
NB_LAST_MSGS = 10

/** Types **/

type user = { int id, string name, option(mindstate) mindwave }
type source = { system } or { string user }
type message = {
  source source,
  string text,
  Date.date date,
}
type media = {
  source source,
  string name,
  string src,
  string mimetype,
  Date.date date,
}
type client_channel = channel(void)
type network_msg =
   {message message}
or {media media}
or {(user, client_channel) connection}
or {user disconnection}
or {stats}
or {user mindstate}

/** Database **/

database intmap(message) /history

/** Top level values **/

exposed Network.network(network_msg) room = Network.cloud("room")
private reference(intmap(user)) users = ServerReference.create(IntMap.empty)
private launch_date = Date.now()

/** Connection **/

server function server_observe(message) {
  match (message) {
  case {connection:(user, client_channel)} :
    ServerReference.update(users, IntMap.add(user.id, user, _))
    Network.broadcast({stats}, room)
    Session.on_remove(client_channel, function() {
      server_observe({disconnection:user})
    })
  case {disconnection:user} :
    ServerReference.update(users, IntMap.remove(user.id, _))
    Network.broadcast({stats}, room)
  default: void
  }
}

_ = Network.observe(server_observe, room)

/** Stats **/

// Compute uptime and memory usage (MB)
server function compute_stats() {
  uptime = Date.between(launch_date, Date.now())
  mem = System.get_memory_usage()/(1024*1024)
  (uptime, mem)
}

client @async function update_stats((uptime, mem)) {
  #uptime = <>Uptime: {Duration.to_formatted_string(Duration.long_time_printer, uptime)}</>
  #memory = <>Memory: {mem} MB</>
}

/** Users **/

client @async function update_users(nb_users, users) {
  #users = <>Users: {nb_users}</>
  #user_list = <ul class="unstyled">{users}</ul>
}

/** Conversation **/

// converts a source into HTML
function source_to_html(source) {
  match (source) {
  case {system} : <span class="system"/>
  case {~user} : <span class="user">{user}</span>
  }
}

private client function generic_update(stats, elements, printer) {
  update_stats(stats)
  List.iter(function(element) {
    date = Date.to_formatted_string(Date.default_printer, element.date)
    time = Date.to_string_time_only(element.date)
    line = <div class="line">
              <span class="date" title="{date}">{time}</span>
              {printer(element)}
           </div>
    #conversation =+ line
  }, elements)
  Dom.scroll_to_bottom(#conversation)
}

client @async function message_update(stats, list(message) messages) {
  generic_update(stats, messages, function(message) {
    source_to_html(message.source) <+>
    <span class="message">{message.text}</span>
  })
}

client @async function media_update(stats, list(media) medias) {
  media_parser = parser {
    case "image/" .*: {image}
    case "audio/" .*: {audio}
    case "video/" .*: {video}
  }
  generic_update(stats, medias, function(media) {
    source_to_html(media.source) <+>
    ( match (Parser.try_parse(media_parser, media.mimetype)) {
      case {some:{image}}:
        <img src="{media.src}" alt="{media.name}"/>
      case {some:{audio}}:
        <audio src="{media.src}"
               controls="controls"
               type="{media.mimetype}"
               preload="auto">
          Your browser does not support the audio tag!
        </audio>
      case {some:{video}}:
        <video src="{media.src}"
               controls="controls"
               preload="auto"
               type="{media.name}">
          Your browser does not support the video tag!
        </video>
      default:
        <span class="media {media.mimetype}"> is sharing a file :
          <a target="_blank" href="{media.src}"
             draggable="true"
             data-downloadurl="{media.mimetype}:{media.name}:{media.src}">{media.name}</a>
        </span>
      } )
  })
}

server function file_uploaded(user)(name, mimetype, key) {
  media = {
    source: {user:user.name},
    ~name,
    src: "/file/{key}",
    ~mimetype,
    date: Date.now(),
  }
  Network.broadcast({~media}, room)
}

server function client_observe(msg) {
  match (msg) {
  case {~message} :
    message_update(compute_stats(), [message])
  case {~media} :
    media_update(compute_stats(), [media])
  case {connection:(user, _)} :
    message = {
      source: {system},
      text : "{user.name} joined the room",
      date : Date.now(),
    }
    message_update(compute_stats(), [message])
  case {disconnection:user} :
    message = {
      source: {system},
      text : "{user.name} left the room",
      date : Date.now(),
    }
    message_update(compute_stats(), [message])
  case {stats} :
    update_stats(compute_stats())
    users = ServerReference.get(users)
            |> IntMap.To.val_list(_)
            |> List.sort_by(function(u){u.name}, _)
    users_html_list =
      List.fold(function(user, acc) {
        mw = mindwave_to_html(user.mindwave)
        <li><span id="{user.id}-state" class="mindwave">{mw}</span> {user.name}</li>
        <+> acc
      }, users, <></>)
    update_users(List.length(users), users_html_list)
  case {mindstate:user} :
    ServerReference.update(users, IntMap.add(user.id, user, _))
    users = ServerReference.get(users) |> IntMap.To.val_list(_)
    waves_list =
      List.fold(function(user, acc) {
        (user.id, user.mindwave) +> acc
      }, users, [])
    update_mindwaves(waves_list)
  default : void
  }
}

/** Init **/

// Init the client from the server
server function init_client(user, client_channel, _) {
  // Observe client
  obs = Network.observe(client_observe, room)
  Network.broadcast({connection:(user, client_channel)}, room)
  // Observe disconnection
  Dom.bind_beforeunload_confirmation(function(_) {
    Network.broadcast({disconnection:user}, room)
    Network.unobserve(obs)
    none
  })
  // Send NB_LAST_MSGS messages
  history_list = IntMap.To.val_list(/history)
  len = List.length(history_list)
  history = List.drop(len-NB_LAST_MSGS, history_list)
  message_update(compute_stats(), history)
}

// Init various scheduling tasks
client function init_scheduling(user, _) {
  Scheduler.timer(MW_TIMER, function(){
    check_mindstate(user)
  })
}

client @async function send_message(broadcast, _) {
  void broadcast(Dom.get_value(#entry))
  Dom.clear_value(#entry)
}

exposed @async function enter_chat(user_name, client_channel) {
  user = {
    id: Random.int(max_int),
    name: user_name,
    mindwave: none,
  }
  function broadcast(text) {
    message = {source:{user:user_name}, ~text, date:Date.now()}
    /history[?] <- message
    Network.broadcast({~message}, room)
  }
  #main =
    <div id=#sidebar>
      <h3>Users online</h3>
      <div id=#user_list/>
      {mindwave_flash}
    </div>
    <div id=#content
         onready={function(e){
                    init_scheduling(user, e)
                    init_client(user, client_channel, e)
                  }}>
      <div id=#stats><div id=#users/><div id=#uptime/><div id=#memory/></div>
      <div id=#conversation/>
      <div id=#chatbar>
        <input id=#entry
               autofocus="autofocus"
               onready={function(_){Dom.give_focus(#entry)}}
               onnewline={send_message(broadcast, _)}
               x-webkit-speech="x-webkit-speech"/>
      </div>
    </div>
}

client @async function join(_) {
  name = Dom.get_value(#name)
  client_channel = Session.make_callback(ignore)
  enter_chat(name, client_channel)
}

/** Server **/

watch_button =
  <iframe src="http://markdotto.github.com/github-buttons/github-btn.html?user={GITHUB_USER}&repo={GITHUB_REPO}&type=watch&count=true&size=large"
          allowtransparency="true" frameborder="0" scrolling="0" width="146px" height="30px"></iframe>

fork_button =
  <iframe src="http://markdotto.github.com/github-buttons/github-btn.html?user={GITHUB_USER}&repo={GITHUB_REPO}&type=fork&count=true&size=large"
          allowtransparency="true" frameborder="0" scrolling="0" width="146px" height="30px"></iframe>

function build_page(content) {
  <div id=#header>
    <h2 class="pull-left">MindChat</h2>
    <div class="buttons pull-left">
      {watch_button}
      {fork_button}
    </div>
  </div>
  <div id=#main>{content}</div>
}

// Page headers
headers =
  Xhtml.of_string_unsafe("
<!--[if lt IE 9]>
<script src=\"//html5shiv.googlecode.com/svn/trunk/html5.js\"></script>
<![endif]-->") <+>
  <meta charset="utf-8"></meta>
  <meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1"></meta>
  <meta name="viewport" content="width=device-width,initial-scale=1"></meta>

// Start page
server function start() {
  page = build_page(
    <h3>The webchat that shows how you feel.</h3>
    <div id=#login class="form-inline">
      <input id=#name
             placeholder="Name"
             autofocus="autofocus"
             onready={function(_){Dom.give_focus(#name)}}
             onnewline={join}/>
       <button class="btn primary"
               onclick={join}>Join</button>
    </div>
  )
  Resource.full_page_with_doctype(
    "MindChat",
    {html5},
    page, headers, {success},
    []
  )
}

// Parse URL
url_parser = parser {
  case (.*): start()
}

Resource.register_external_js("/resources/neurosky/FlashToJs/api.js")

// Start the server
Server.start(Server.http, [
  { resources : @static_resource_directory("resources") }, // include resources directory
  { register : [
      "/resources/css/style.css",
      "/resources/neurosky/icons.css",
    ] }, // include CSS in headers
  { custom : url_parser } // URL parser
])
