<?xml version="1.0" encoding="windows-1251"?>
<Config xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <DefaultConnectionType>FirebirdSql.Data.FirebirdClient.FbConnection,FirebirdSql.Data.FirebirdClient</DefaultConnectionType>
  <DefaultSyncDatabaseConnectionType>SB.Sync.Svc.FbSyncDatabaseConnection,SB.Sync.Svc</DefaultSyncDatabaseConnectionType>
  <DefaultListenAddress>net.tcp://localhost:8881/sync</DefaultListenAddress>
  <DefaultSyncDelay>300</DefaultSyncDelay>
  <DefaultLinkRetries>5</DefaultLinkRetries>
  <DefaultRetryAfterErrorsDelay>7200</DefaultRetryAfterErrorsDelay>
  <Connections>
    <Connection xsi:type="Database" Name="kredclient_$suffix$" AllowedRemoteAccess="true" ListenEvents="false">
      <ConnectionString>Database=$svr$:kredclient;User=$user$;Password=$password$;Pooling=false</ConnectionString>
    </Connection>
    <Connection xsi:type="Database" Name="ch_sk" AllowedRemoteAccess="true" ListenEvents="false">
      <ConnectionString>Database=$svr$:vkl;User=$user$;Password=$password$;Pooling=false</ConnectionString>
    </Connection>
    <Connection xsi:type="Database" Name="valreestr_$suffix$" AllowedRemoteAccess="true" ListenEvents="false">
      <ConnectionString>Database=$svr$:valreestr;User=$user$;Password=$password$;Pooling=false</ConnectionString>
    </Connection>
    <Connection xsi:type="RemoteService" Name="oper_main_remote">
      <Address>$addr$</Address>
      <DatabaseName>oper_main</DatabaseName>
    </Connection>
    <Connection xsi:type="RemoteService" Name="ch_sk_main">
      <Address>$addr$</Address>
      <DatabaseName>ch_sk_main</DatabaseName>
    </Connection>
    <Connection xsi:type="RemoteService" Name="kredclient_main">
      <Address>net.tcp://192.168.135.211:8881/sync</Address>
      <DatabaseName>kredclient_main</DatabaseName>
    </Connection>
    <Connection xsi:type="RemoteService" Name="valreestr_$suffix$_main">
      <Address>$addr$</Address>
      <DatabaseName>valreestr_$suffix$_main</DatabaseName>
    </Connection>
    <Connection xsi:type="Database" Name="oper_ldb" AllowedRemoteAccess="true" ListenEvents="false">
      <ConnectionString>Database=10.135.7.16:oper;User=SYSDBA;Password=53498;Charset=WIN1251;Pooling=false</ConnectionString>
    </Connection>
  </Connections>
  <Links>
    <SyncLink Name="Вклады: Сковородино - Благовещенск" Enabled="false">
      <Local>ch_sk</Local>
      <Remote>ch_sk_main</Remote>
      <LocalId>202070010</LocalId>
      <LocalFilters />
      <RemoteFilters />
      <LinkRetries>0</LinkRetries>
      <RetryAfterErrorsDelay>0</RetryAfterErrorsDelay>
    </SyncLink>
    <SyncLink Name="КредКл: Сковородино - Благовещенск" Enabled="false">
      <Local>kredclient_$suffix$</Local>
      <Remote>kredclient_main</Remote>
      <Order>LocalRemote</Order>
      <LocalId>205070010</LocalId>
      <RemoteId>205070002</RemoteId>
      <LocalFilters />
      <RemoteFilters>
        <Filter xsi:type="FieldValueRowFilter" FieldName="BRANCH_ID" FieldValue="7" />
      </RemoteFilters>
      <LinkRetries>0</LinkRetries>
      <RetryAfterErrorsDelay>0</RetryAfterErrorsDelay>
    </SyncLink>
    <SyncLink Name="ВалРеестр: Сковородино-Благовещенск" Enabled="true">
      <Local>valreestr_$suffix$</Local>
      <Remote>valreestr_$suffix$_main</Remote>
      <LocalId>206070010</LocalId>
      <SyncDelay>3600</SyncDelay>
      <LocalFilters />
      <RemoteFilters />
      <LinkRetries>0</LinkRetries>
      <RetryAfterErrorsDelay>0</RetryAfterErrorsDelay>
    </SyncLink>
    <SyncLink Name="Операционный день: Сковородино-Благовещенск" Enabled="false">
      <Local>oper_ldb</Local>
      <Remote>oper_main_remote</Remote>
      <LocalId>201070001</LocalId>
      <RemoteId>201070002</RemoteId>
      <LocalFilters />
      <RemoteFilters />
      <LinkRetries>0</LinkRetries>
      <RetryAfterErrorsDelay>0</RetryAfterErrorsDelay>
    </SyncLink>
  </Links>
  <Params>
    <Param Name="addr" Value="net.tcp://192.168.135.211:8881/sync" />
    <Param Name="suffix" Value="skov" />
    <Param Name="svr" Value="svr35g1" />
    <Param Name="user" Value="SYSDBA" />
    <Param Name="password" Value="53498" />
  </Params>
</Config>