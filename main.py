import json

from flask import Flask, request, render_template
from flask_sockets import Sockets
from gluster.cli import georep


app = Flask(__name__)
sockets = Sockets(app)
ws_clients = set()
app.debug = True


@app.route("/")
def dashboard():
    return render_template("index.html")


@app.route("/get")
def get():
    return json.dumps(georep.status())


@sockets.route('/events')
def events_socket(ws):
    ws_clients.add(ws)
    while not ws.closed:
        message = {"message": ws.receive()}
        ws.send(json.dumps(message))


def broadcast(message):
    """
    Broadcast message to all connected Websocket Clients
    if a client is closed then remove from the clients list
    so that broadcast will not try sending message to that client
    in future.
    """
    closed_ws_clients = []
    for ws in ws_clients:
        if ws.closed:
            closed_ws_clients.append(ws)
            continue
        ws.send(message)

    for cws in closed_ws_clients:
        ws_clients.remove(cws)


@app.route("/listen", methods=["POST"])
def listen_gluster_events():
    data = request.json
    if data is None:
        return "OK"

    if data.get("event").startswith("GEOREP_") or \
       data.get("event").startswith("VOLUME_"):
        broadcast("get")

    # Acknoledge Gluster that message recieved
    return "OK"


if __name__ == "__main__":
    from gevent import pywsgi
    from geventwebsocket.handler import WebSocketHandler
    server = pywsgi.WSGIServer(('', 5000), app, handler_class=WebSocketHandler)
    server.serve_forever()
