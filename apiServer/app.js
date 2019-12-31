var express = require('express');
const bodyParser = require('body-parser')
const cors = require('cors')
const morgan = require('morgan')
const uuid4 = require('uuid4');

const redis = require('redis') 
const redisClient = redis.createClient({ 
  host : process.env.COUNTERIP, 
  port : 6379
});

var app = express();
var http = require('http').Server(app);
var port = process.env.PORT || 3000;

app.use(morgan('combined'))
app.use(bodyParser.json())
app.use(cors())

var counters = [];

var incrementer = setInterval(incCounters,1000);

function incCounters(){
  for(var cIndex=0; cIndex<counters.length; cIndex++){
    counters[cIndex].current++;
    //check counter time reached
    if(counters[cIndex].current >= counters[cIndex].to){
      //del from redis
      delCounter(counters[cIndex].uuid);
      //del local
      counters.splice(cIndex,1);
      cIndex--;
    } else {
      var counterObj = counters[cIndex];
      //check if counter exists in redis
      redisClient.get(counterObj.uuid, function(err, reply){
        var reply = JSON.parse(reply);
        if(reply== null){
        } else if(reply.status == "running"){
          //update redis counter
          redisClient.set(reply.uuid, JSON.stringify({
            uuid : reply.uuid,
            current : reply.current+1,
            to : counterObj.to,
            status : "running"
          }));
        } else {
          //if counter is stopped, delete from local
          delCounterLocal(reply.uuid);
          //del from redis
          delCounter(reply.uuid);
        }        
      })      
    }
  }
}

//Delete counter from local list
function delCounterLocal(counterID){
  for(var i=0; i<counters.length; i++){
    if(counters[i].uuid == counterID){
      counters.splice(i,1);
      break;
    }
  }
}

//Delete Counter from redis
function delCounter(counterID){
  redisClient.del(counterID, function(err, resp){
    if(resp ==1){
      console.log("[Counter time reached] del success: " + counterID);
    } else {
      console.log("[Counter time reached] del fail: " + counterID);
    }
  });
}

//Return hostnum
app.get('/', function(req, res){
  res.send('host'+process.env.HOSTNUM+'\n');
});

//Flush Redis
app.get('/flushRedis', function(req, res){
  redisClient.flushdb('ASYNC', function(){
    console.log("success");
  });
  res.end();
});

//Create counter (with 'to' param)
app.post('/counter/', function(req, res){

  var to = req.param('to');
  
  //local counter object
  var counter = {
    uuid : uuid4(),
    current : 0,
    to : parseInt(to)
  }
  counters.push(counter);
  
  //add counter to redis
  redisClient.set(counter.uuid, JSON.stringify({
    uuid : counter.uuid,
    current : counter.current,
    to : counter.to,
    status : "running"
  }));

  res.send(counter.uuid + '\n');
});

//Get list of UUID's of all counters in redis
app.get('/counter/', function(req, res){
  redisClient.keys('*', function (err, keys) {
    if (err) return console.log(err);
    var keysStr = "";
    for(var i = 0, len = keys.length; i < len; i++) {
      keysStr += (keys[i]) + '\n'
    }
    res.send(keysStr);
  }); 
});

//Get total number of counters on redis
app.get('/counterCount/',function(req, res){
  redisClient.keys('*', function (err, keys) {
    if (err) return console.log(err);
    res.send(''+keys.length);
  }); 
});

//Stop a counter
app.post('/counter/:id/stop/', function(req, res) {
  redisClient.set(req.params.id, JSON.stringify({
    uuid : req.params.id,
    current : 0,
    to : 0,
    status : "stopped"
  }), function(err, reply){
    if(reply ==1){
          console.log("del success: " + req.params.id);
        } else {
          console.log("del fail: " + req.params.id);
        }
    res.end();
  });
});

//Get counter info from redis
app.get('/counter/:id', function(req, res) {
  redisClient.get(req.params.id, function(err, reply) {
    if (err) return console.log(err);
    if(reply != null){
      var replyJSON = JSON.parse(reply);
      if(replyJSON.status == "running"){
        var tmpCounter = {
          current : replyJSON.current,
          to : replyJSON. to
        }
        res.send(JSON.stringify(tmpCounter) + '\n');
      } else {
        res.end();
      }
    } else {
      res.end();
    }    
  });
});

app.listen(port, function(){
  console.log('listening on port:' + port);
});
