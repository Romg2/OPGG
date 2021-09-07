#!/usr/bin/env python
# coding: utf-8

# In[ ]:


import pandas as pd
import requests

def champion_load():
    # 각 버전 (챔피언, 룬, 아이템 등..)
    champ_ver = requests.get('https://ddragon.leagueoflegends.com/realms/na.json').json()['n']['champion']
    championJsonURL = 'http://ddragon.leagueoflegends.com/cdn/' + champ_ver + '/data/en_US/champion.json'

    # 챔피언 정보 url
    request = requests.get(championJsonURL)
    champion_data = request.json()

    # 챔피언 id, name 데이터 프레임
    champion_dict = {}

    for c_name in champion_data['data'].keys() :
        champion_dict[int(champion_data['data'][c_name]['key'])]=c_name

    champion = pd.DataFrame.from_dict(champion_dict, orient = 'index', columns = ['champion'])
    
    return champion

