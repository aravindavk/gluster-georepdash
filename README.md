As an experiment to showcase the capabilities of Gluster Events APIs,
Created a dashboard for [Gluster Geo-replication](http://gluster.readthedocs.io/en/latest/Administrator%20Guide/Geo%20Replication/).

**Note: This is not ready for production use Yet!**

Real-time notifications/UI change only works with Gluster 3.9 or
above, but dashboard will work with older versions of gluster too.

## Install
Install the following Python dependencies using,

    sudo pip install flask flask_sockets glustercli

Install `elm` and `bower` using,

    sudo npm install -g bower elm

Update the `serverName` in `App.elm` and then generate `static/app.js`
using,(editing serverName should be automatic, this is code bug! will
fix later)

    elm-package install
    elm-make App.elm --output static/app.js

Install `purecss` for style using,

    cd static
    bower install

## Usage
Start the `main.py` in any node of the Cluster. Dashboard can be
accessed using `http://nodename:5000`

Test and register this node as Events API subscriber by calling `webhook-add`
command. Read more about starting Events service [here](http://gluster.readthedocs.io/en/latest/Administrator%20Guide/Events%20APIs/)

    gluster-eventsapi webhook-test http://nodename:5000/listen

If Webhook status is OK from all nodes, then add webhook using,

    gluster-eventsapi webhook-add http://nodename:5000/listen

Thats all! If everything is okay, dashboard will show realtime
Geo-replication status.

## Screenshots

**UI Changes when a Geo-rep session is stopped from anywhere in Cluster**  
![When Geo-replication Stopped](https://github.com/aravindavk/gluster-georepdash/raw/master/screenshots/georep_stop.gif)

** UI Changes when a Geo-rep session goes to Faulty**  
![When Geo-replication is Faulty](https://github.com/aravindavk/gluster-georepdash/raw/master/screenshots/georep_faulty.gif)

### UI/Dashboard Notes
- UI is very raw since it is created for demo purpose
- Frontend developed using [Elm](http://elm-lang.org/)
- No event available for change in "Last Synced" column, So that
  column value will not match with realtime output from status
  command. Refresh the page to see the latest status.
