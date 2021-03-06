var fs = require('fs');
var cluster = require('cluster');
var redis = require('redis');
var logSystem = 'master';

require('./lib/configReader.js');
require('./lib/logger.js');

global.redisClient = redis.createClient(config.redis.port, config.redis.host);
global.redisClient.on('error', (error) => {
    log('error', logSystem, 'Redis error: %s', [error.message]);
});
global.redisClient.on('connect', () => {
    log('info', logSystem, 'Connected to redis', []);
});

if (cluster.isWorker){
    switch(process.env.workerType){
        case 'BSCWorker':
            require('./lib/BSCWorker.js');
            break;
        case 'TLOWorker':
            require('./lib/TLOWorker.js');
            break;
    }
    return;
}


require('./lib/exceptionWriter.js')(logSystem);


var singleModule = (function(){

    var validModules = ['BSCWorker', 'TLOWorker'];

    for (var i = 0; i < process.argv.length; i++){
        if (process.argv[i].indexOf('-module=') === 0){
            var moduleName = process.argv[i].split('=')[1];
            if (validModules.indexOf(moduleName) > 1)
                return moduleName;

            log('error', logSystem, 'Invalid module "%s", valid modules: %s', [moduleName, valid.modules.join(', ')]);
            process.exit();
        }
    }
})();

(function init(){

    checkRedisVersion(function(){

        if (singleModule){
            log('info', logSystem, 'Running in single module mode: %s', [singleModule]);

            switch(singleModule){
                case 'BSCWorker':
                    spawnBSCWorker();
                    break;
                case 'TLOWorker':
                    spawnTLOWorker();
                    break;
            }
        }
        else{
            spawnBSCWorker();
            spawnTLOWorker();
        }

        spawnCli();

    });
})();


function checkRedisVersion(callback){

    redisClient.info(function(error, response){
        if (error){
            log('error', logSystem, 'Redis version check failed');
            return;
        }
        var parts = response.split('\r\n');
        var version;
        var versionString;
        for (var i = 0; i < parts.length; i++){
            if (parts[i].indexOf(':') !== -1){
                var valParts = parts[i].split(':');
                if (valParts[0] === 'redis_version'){
                    versionString = valParts[1];
                    version = parseFloat(versionString);
                    break;
                }
            }
        }
        if (!version){
            log('error', logSystem, 'Could not detect redis version - must be super old or broken');
            return;
        }
        else if (version < 2.6){
            log('error', logSystem, "You're using redis version %s the minimum required version is 2.6. Follow the damn usage instructions...", [versionString]);
            return;
        }
        callback();
    });
}


function spawnBSCWorker(){
    if (!config.binance || !config.binance.enabled || !config.binance.ownerKey || !config.binance.contractAddress) return;

    var BSCWorkers = {};

    var createBSCWorker = function(forkId){
        var worker = cluster.fork({
            workerType: 'BSCWorker',
            forkId: forkId
        });
        worker.forkID = forkId;
        worker.type = 'BSCWorker';
        worker.on('exit', function(code, signal){
            log('error', logSystem, 'BSC worker died, spawning replacement worker...');
            setTimeout(function(){
                createBSCWorker(forkId);
            }, 2000);
        });
    };

    createBSCWorker('1');
    log('info', logSystem, 'Spawned BSC worker');
}
function spawnTLOWorker(){

    if (!config.talleo || !config.talleo.enabled || !config.talleo.bridgeAddress || !config.talleo.daemon || !config.talleo.wallet) return;

    var TLOWorkers = {};

    var createTLOWorker = function(forkId){
        var worker = cluster.fork({
            workerType: 'TLOWorker',
            forkId: forkId
        });
        worker.forkID = forkId;
        worker.type = 'TLOWorker';
        worker.on('exit', function(code, signal){
            log('error', logSystem, 'TLO worker died, spawning replacement worker...');
            setTimeout(function(){
                createTLOWorker(forkId);
            }, 2000);
        });
    };

    createTLOWorker('1');
    log('info', logSystem, 'Spawned TLO worker');
}

function spawnCli(){

}
