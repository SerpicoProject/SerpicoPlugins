# SerpicoPlugins
This repository includes plugins for Serpico. The [wiki](https://github.com/SerpicoProject/SerpicoPlugins/wiki/Main-Page) has more information on how to build plug-ins.


Plug-ins are ideally suited to:
- Add functionality that involves third party components
- Proto-typing functionality

# Installation

## Install the Project
From the Serpico project root directory:
```
cd plugins
git clone https://github.com/SerpicoProject/SerpicoPlugins.git
```

## Enable the plugin
To enable a plugin, modify the config.json file included in the plugin. Specifically:
```
enabled: true
```
