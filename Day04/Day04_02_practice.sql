# 1. 패치 버전 및 패치 날짜를 출력하는 쿼리 작성
# 출력 컬럼: `lolVersionHistory` 테이블에 있는 모든 컬럼
EXPLAIN
SELECT *
FROM lolVersionHistory FORCE INDEX(`date`);




# 2. 본인 계정 닉네임(혹은 `Hide on bush`)에 대한 정보를 출력하는 쿼리 저장
# 출력 컬럼: 소환사id, 소환사 닉네임
EXPLAIN
SELECT id, name
FROM opSummoner FORCE INDEX(`ix_name`)
WHERE name = 'Romg2';




# 3. summonerId = 4460427인 플레이어가 플레이한 게임 정보를 10개만 출력하는 쿼리 작성
# 출력 컬럼: 게임id, 챔피언id, 포지션, 승패
EXPLAIN
SELECT gameId, championId, position, result
FROM p_opGameStats FORCE INDEX(`ix_summonerId_createDate`)
WHERE summonerId = 4460427
ORDER BY createDate
LIMIT 10;




# 4. 자유랭크 랭킹 1~20위의 랭크 정보를 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 포인트(LP), 승리 수, 패배 수
EXPLAIN
SELECT summonerId, leaguePoints, wins, losses
FROM opSummonerLeague
WHERE queueType = 'RANKED_FLEX_SR'
AND tier = 'CHALLENGER'
AND `rank` = 1
ORDER BY leaguePoints DESC
LIMIT 20;
# AND `rank` = 1: 챌린저는 모두 `rank`가 1이지만 인덱스를 태워 속도를 향상 시키려고 사용
# AND `rank` = 1 조건의 유무에 따라 EXPLAIN ref가 달라짐을 확인 가능




# 5. 솔로랭크 티어, 랭크별로 소환사 수 출력하는 쿼리 작성
# 출력 컬럼: 티어, 랭크, 유저 수(userCount)
# `tier` 컬럼은 단순 CHARACTER가 아니라 ordering이 된 특수한 데이터 타입
# 높은 티어(챌린저 > 그마> ...), 높은 랭크(1,2,3,4)가 위에 출력
EXPLAIN
SELECT tier, `rank`, COUNT(*) AS userCount
FROM opSummonerLeague
WHERE queueType = 'RANKED_SOLO_5x5'
GROUP BY tier ,`rank`
ORDER BY tier DESC,`rank`;




# 6. 솔로랭크 티어, 랭크별로 "승급전" 진행 중인 유저 수를 출력하는 쿼리 작성
# 출력 컬럼: 티어, 랭크, 유저 수(userCount)
# 높은 티어(챌린저>그랜드마스터>...), 높은 랭크(1>2>3>4)가 위에 출력되게 하세요.
# HAVING을 사용하는 쿼리, HAVING을 사용하지 않는 쿼리를 둘 다 작성하세요.

# 6-1 HAVING (X)
EXPLAIN
SELECT tier, `rank`, COUNT(*) AS userCount
FROM opSummonerLeague
WHERE queueType = 'RANKED_SOLO_5x5'
AND seriesTarget IS NOT NULL
AND leaguePoints = 100
GROUP BY tier ,`rank`
ORDER BY tier DESC,`rank`;
# seriesTarget은 승급전인 경우만 값이 존재하며 이겨야하는 판수를 의미
# AND leaguePoints = 100: 인덱스에 포함된 컬럼이기에 속도 향상을 위해 사용
# 마스터부터는 승급전이 없고 LP 기준이 100점이 아니기에 당연히 출력되지 않음(seriesTarget이 NULL)

# 6-2 HAVING (O)
EXPLAIN
SELECT tier, `rank`, COUNT(seriesTarget) AS userCount
FROM opSummonerLeague
WHERE queueType = 'RANKED_SOLO_5x5'
AND leaguePoints = 100
GROUP BY tier ,`rank`
HAVING userCount > 1
ORDER BY tier DESC,`rank`;
# COUNT, SUM, AVG 등은 NULL을 제외하고 연산하는 성질을 이용해서 * 대신 seriesTarget 사용




# 7. 닉네임이 'Hide on'으로 시작하거나 'SKT T1'으로 시작하는 계정 정보를 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 소환사 닉네임
# 각 분류마다 10개씩만 출력하세요. 총 20개 (Hide on ## 10개 + SKT T1 ## 10개)
# SUBSTRING을 사용하지 말고 작성하세요.
EXPLAIN
(SELECT id, name
FROM opSummoner
WHERE name LIKE 'Hide on%'
LIMIT 10)
UNION

(SELECT id, name
FROM opSummoner
WHERE name LIKE 'SKT T1%'
LIMIT 10);
# SUBSTRING을 사용하면 컬럼에 연산이 걸려서 인덱스를 못타므로 지양
# 인덱스를 탈 때 맨 앞을 보고 찾아야므로 LIKE '%문자'도 인덱스를 못탄다.
# 괄호를 반드시 묶어야함




# 8. 솔로랭크 랭킹 1~10위의 랭크 정보를 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 닉네임, 티어, 랭크, LP, 판 수(gameCount), 승률(Winrate)
EXPLAIN
SELECT T1.summonerId, name, tier, `rank`, leaguePoints, (wins+losses) AS gameCount, (wins/(wins+losses)) AS Winrate
FROM opSummonerLeague T1 # DRIVEN TABLE
INNER JOIN opSummoner T2 # DRIVING TABLE
ON T1.summonerId = T2.id
WHERE T1.queueType = 'RANKED_SOLO_5x5'
AND tier = 'CHALLENGER'
AND `rank` = 1
ORDER BY leaguePoints DESC
LIMIT 10;




# 9. 8번 문제에 나온 10명의 광복절 연휴(2021년 8월 14일~2021년 8월 16일) 승률을 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 닉네임, 판 수(gameCount), 승률(Winrate)
# 다시하기 게임 제외합니다.
EXPLAIN
SELECT STRAIGHT_JOIN T1.summonerId, name,
                     COUNT(*) AS gameCount, COUNT(IF(result ='WIN',1,NULL))/COUNT(*) AS Winrate
FROM opSummonerLeague T1
INNER JOIN opSummoner T2
ON T1.summonerId = T2.id
INNER JOIN p_opGameStats T3
ON T1.summonerId = T3.summonerId

WHERE queueType = 'RANKED_SOLO_5x5'  # opSummonerLeague.summonerId를 유니크하게 해주는..
AND tier = 'CHALLENGER'
AND `rank` = 1
AND result != 'UNKNOWN'
AND createDate >= '2021-08-14'
AND createDate <'2021-08-17'

GROUP BY leaguePoints, T1.summonerId
ORDER BY leaguePoints DESC
LIMIT 10;
# 8번 문제와 달리 p_opGameStats을 JOIN 하여 summonerId 하나당 여러 ROW가 붙으므로 gameCount는 COUNT()로 계산
# COUNT(IF(result ='WIN',1,NULL))는 SUM(IF(result ='WIN',1,0))로도 가능

# STRAIGHT JOIN: 왼쪽 드라이빙 테이블에 비해 오른쪽 테이블의 데이터가 너무 많고 필요 없는 데이터가 많은 경우
# 여기선 opSummonerLeague가 드라이빙 테이블, 솔랭/자랭이 있어 opSummoner보다 크지만 솔랭만 사용할 거임
# p_opGameStats은 summonerId 하나당 여러 게임 정보가 존재
# STRAIGHT JOIN을 지정하지 않아도 알아서 되는 경우도 있지만 직접 지정

# GROUP BY leaguePoints를 넣지 않으면 Column leaguePoints must be either aggregated, or mentioned in GROUP BY clause
# 이러한 에러가 뜨지만 실행은 된다.




# 10. 솔랭이 "챌린저"인 300명에 대해 솔로랭크 게임당 용 처치 수를 내림차순으로 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 닉네임, 게임당 용 처치 수(AvgDragonKills)
# 다시하기 게임 제외합니다.
EXPLAIN
SELECT T1.summonerId, name, AVG(dragonKills) AS AvgDragonKills

FROM opSummonerLeague T1
INNER JOIN opSummoner T2
ON T1.summonerId = T2.id
INNER JOIN p_opGameStats T3
ON T1.summonerId = T3.summonerId
INNER JOIN opGameTeam T4
ON T3.gameId = T4.gameId
INNER JOIN opGame T5
ON T3.gameId = T5.gameId AND T3.teamId = T4.teamId # 한 게임당 블루,레드 2개이므로 소환사의 팀을 지정

WHERE queueType = 'RANKED_SOLO_5x5' # 티어확인을 위한 솔랭
AND tier = 'CHALLENGER'
AND `rank` = 1
AND subType = 420                   # 게임이 솔랭
AND result != 'UNKNOWN'

GROUP BY T1.summonerId, name
ORDER BY AvgDragonKills DESC;




# 11. 솔로 랭크 "마스터" 이상 소환사가 포함된 솔로 랭크 게임에서 챔피언별로 밴된 횟수(banCount)를 출력하는 쿼리 작성
# 출력 컬럼: 챔피언id, 밴된 횟수(banCount)
# `p_opGameStats`의 `tierRank` 대신 opSummonerLeague의 `tier` 정보를 이용하세요.
# 다시하기 게임 제외합니다.
# banCount 내림차순으로 정렬하세요.
# Subquery를 사용하는 쿼리, 사용하지 않는 쿼리를 둘 다 작성하세요.

# 11-1 SUBQUERY (X)
EXPLAIN
SELECT T5.championId, COUNT(DISTINCT(T5.gameId)) AS banCount
FROM opSummonerLeague T1
INNER JOIN p_opGameStats T2
ON T1.summonerId = T2.summonerId
INNER JOIN opGame T4
ON T2.gameId = T4.gameId
INNER JOIN opBannedChampion T5
ON T2.gameId = T5.gameId

WHERE queueType = 'RANKED_SOLO_5x5' # 티어확인을 위한 솔랭
AND tier IN ('MASTER', 'CHALLENGER', 'GRANDMASTER')
AND `rank` = 1
AND subType = 420                   # 게임이 솔랭
AND result != 'UNKNOWN'

GROUP BY T5.championId
ORDER BY banCount DESC;
# 1. opSummonerLeague에서 summonerId를 가져옴 / queueType: 솔랭, tier: 마스터 이상
# 2. summonerId별 gameId를 p_opGameStats에서 가져옴 / result: 다시하기 제외
# 3. p_opGameStats의 gameId와 일치하는 경우 opGame의 subType 가져옴 / subType: 게임타입솔랭
# 4. 위 조건을 만족하는 gameId가 opBannedChampion의 gameId와 일치하는 경우 해당 게임의 밴 챔피언 가져오기
# 5. COUNT에서 DISTINCT 사용하는 이유는 예를 들어 똑같은 gameId와 A에 2개,B에 3개 있으면 INNER JOIN시 6개가 됨

# 11-1 강사님 풀이
EXPLAIN
SELECT STRAIGHT_JOIN b.championId, COUNT(DISTINCT(b.gameId)) AS banCount
FROM opSummonerLeague l FORCE INDEX (ix_queueType_tier_rank_leaguePoints)
INNER JOIN p_opGameStats p
ON p.summonerId = l.summonerId
INNER JOIN opGame o
ON o.gameId = p.gameId
INNER JOIN opBannedChampion b
ON b.gameId = o.gameId
WHERE subType = 420
AND result != 'UNKNOWN'
AND queueType = 'RANKED_SOLO_5x5'
AND tier IN ('MASTER','GRANDMASTER','CHALLENGER')
GROUP BY b.championId
ORDER BY banCount DESC;

# 11-2 SUBQUERY (O)
EXPLAIN
SELECT b.championId, COUNT(*) AS banCount
FROM opBannedChampion b
WHERE gameId IN (
    SELECT DISTINCT(p.gameId)
    FROM p_opGameStats p
    INNER JOIN opSummonerLeague l
    ON p.summonerId = l.summonerId
    INNER JOIN opGame o
    ON p.gameId = o.gameId
    WHERE subType = 420
    AND result != 'UNKNOWN'
    AND queueType = 'RANKED_SOLO_5x5'
    AND tier IN ('MASTER','GRANDMASTER','CHALLENGER')
    )
GROUP BY b.championId
ORDER BY banCount DESC;
# DISTINCT 아니어도 되지만 더 깔끔




# 12. 2021년 8월 18일 솔로 랭크 게임에서 각 챔피언의 픽 횟수, 승률, KDA 출력
# 출력 컬럼: 챔피언id, 픽된 횟수(pickCount), KDA
# 다시하기 게임 제외합니다.
# pickCount 내림차순으로 정렬하세요.
# KDA = (KILL + ASSIST) / DEATH
EXPLAIN
SELECT P.championId, COUNT(*) AS pickCount, SUM(championsKilled+assists)/SUM(numDeaths) AS KDA
FROM p_opGameStats P
INNER JOIN opGame G
ON P.gameId = G.gameId

WHERE G.createDate >= '2021-08-18'
AND G.createDate < '2021-08-19'
# WHERE P.createDate >= '2021-08-18'
# AND P.createDate < '2021-08-19'
AND P.result != 'UNKNOWN'
AND G.subType = 420
GROUP BY P.championId
ORDER BY pickCount DESC;
# createDate는 양쪽에 있지만 p_opGameStats 걸 사용하면 시간 훨씬 걸린다.
# 둘다 createDate 인덱스가 있긴하지만 opGame과 달리 p_opGameStats은 gameId가 10개 씩 박혀서 그런게 아닐까?
