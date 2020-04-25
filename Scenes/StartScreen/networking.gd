extends Node


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
#var SERVER_IP = "127.0.0.1"
#var SERVER_PORT = 8439
var MAX_PLAYERS = 2
var my_ip = _get_public_ip()
var player_info = {}
var my_info = {name = "player"}


# Called when the node enters the scene tree for the first time.
func _ready():
	_show_ip_and_port()
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	# close networking
#	get_tree().set_network_peer(null)


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _connect():
	var is_server = get_node("cb_host").pressed
	print("is_server = %s" % is_server)
	
	if (is_server):
		var server_port = get_node("txt_server_port").text
		var peer = NetworkedMultiplayerENet.new()
		peer.create_server(int(server_port), MAX_PLAYERS)
		get_tree().set_network_peer(peer)
		print("You're now connected as a server at port %s:%s" % [my_ip, server_port])
	else:
		var selected_ip = get_node("txt_ip").text
		var selected_port = get_node("txt_port").text
		var peer = NetworkedMultiplayerENet.new()
		peer.create_client(selected_ip, int(selected_port))
		get_tree().set_network_peer(peer)
		print("You're now connected as a client to %s" % selected_ip)
		
remote func register_player(info):
	# Get the id of the RPC sender.
	var id = get_tree().get_rpc_sender_id()
	print("Received player info: %s" % info)
	# Store the info
	player_info[id] = info
	

static func _get_public_ip():
	var rx = RegEx.new()
	rx.compile("^([0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)$")
	var ips = IP.get_local_addresses()
	for ip in ips:
		var result = rx.search(ip)
		if result and ip != "127.0.0.1":
			return ip
	return null

######## server callbacks
func _player_connected(id):
	if (id < 1): # this should be treated as an invalid connection per docs
		pass
	
	rpc_id(id, "register_player", my_info)
	
	var name = id
	if (id == 1):
		name = "server"
	print("%s connected" % name)
	# do not allow any more connections
	get_tree().set_refuse_new_network_connections(true)
	_show_select_spaceship_package()

func _player_disconnected(id):
	var disconnected_name = player_info.get(id).name
	player_info.erase(id)
	print("%s disconnected." % disconnected_name)
	
######## client callbacks
func _connected_ok():
	print("Connected to server.")
	
func _server_disconnected():
	print("Disconnected from server.")

func _connected_failed():
	print("Could not connect to server")
	
######## ui control
func _show_ip_and_port():
	var ip = IP.get_local_addresses()
	get_node("lbl_ip_and_port").text = "Your IP: %s" % my_ip

func _on_cb_host_pressed():
	_show_controls(true)

func _on_cb_client_pressed():
	_show_controls(false)

func _on_btn_connect_pressed():
	_connect()

func _show_controls(is_host):
	get_node("lbl_ip_and_port").visible = is_host
	get_node("lbl_ip_and_port2").visible = is_host
	get_node("txt_server_port").visible = is_host
	get_node("cb_host").pressed = is_host
	get_node("cb_client").pressed = !is_host
	get_node("txt_ip").visible = !is_host
	get_node("txt_port").visible = !is_host
	get_node("lbl_ip").visible = !is_host
	get_node("lbl_port").visible = !is_host

func _show_select_spaceship_package():
	pass
