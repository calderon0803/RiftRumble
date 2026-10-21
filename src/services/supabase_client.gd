## Cliente HTTP mínimo para Supabase (Auth + RPC de PostgREST).
##
## Solo usa la clave PÚBLICA del proyecto (publishable/anon), pensada para estar
## en el cliente: la seguridad la ponen RLS y las funciones del servidor. La clave
## de servicio (service_role / secret) NUNCA debe aparecer en el juego.
##
## Cada método devuelve { ok: bool, status: int, data: Variant, error: String }.
extends Node

var url := ""
var api_key := ""
var timeout_secs := 10.0


func configured() -> bool:
	return url != "" and api_key != ""


## Crea un usuario anónimo (invitado). Requiere activar «Anonymous Sign-Ins».
func sign_up_anonymous() -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/auth/v1/signup", {data = {}}, "")


func refresh(refresh_token: String) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/auth/v1/token?grant_type=refresh_token",
			{refresh_token = refresh_token}, "")


## Llama a una función SQL expuesta (POST /rest/v1/rpc/<nombre>).
func rpc_call(function_name: String, params: Dictionary, access_token: String) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/rest/v1/rpc/" + function_name, params, access_token)


func select(table: String, query: String, access_token: String) -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, "/rest/v1/%s?%s" % [table, query], null, access_token)


func _request(method: int, path: String, body, access_token: String) -> Dictionary:
	if not configured():
		return {ok = false, status = 0, data = null, error = "not_configured"}
	var http := HTTPRequest.new()
	http.timeout = timeout_secs
	add_child(http)
	var headers := PackedStringArray([
		"apikey: " + api_key,
		"Content-Type: application/json",
		"Authorization: Bearer " + (access_token if access_token != "" else api_key),
	])
	var payload := "" if body == null else JSON.stringify(body)
	var err := http.request(url.trim_suffix("/") + path, headers, method, payload)
	if err != OK:
		http.queue_free()
		return {ok = false, status = 0, data = null, error = "request_failed_%d" % err}
	var res: Array = await http.request_completed
	http.queue_free()
	var result: int = res[0]
	var status: int = res[1]
	var text: String = (res[3] as PackedByteArray).get_string_from_utf8()
	var data = JSON.parse_string(text) if text != "" else null
	if result != HTTPRequest.RESULT_SUCCESS:
		return {ok = false, status = 0, data = null, error = "network_%d" % result}
	if status < 200 or status >= 300:
		var msg := ""
		if data is Dictionary:
			msg = str(data.get("message", data.get("msg", data.get("error_description", data.get("error", "")))))
		return {ok = false, status = status, data = data, error = msg if msg != "" else "http_%d" % status}
	return {ok = true, status = status, data = data, error = ""}
