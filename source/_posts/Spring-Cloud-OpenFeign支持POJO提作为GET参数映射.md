---
title: Spring Cloud OpenFeign支持POJO提作为GET参数映射
date: 2019-04-23 11:35:27
tags:
---
> 当我们在SpringCloud项目中引入spring-cloud-starter-openfeign时，如果我们用Feign发送Get请求时，采用POJO对象传递参数，那么会可能会出现异常。那么如果你又不想用@RequestParam一个个参数写在调用方法内，有什么好的解决方案吗？

下面是我在调用某个接口，GET请求：

```java
@FeignClient(name = "BiaoClient", url = "${boss.biao.url}")
public interface BiaoClient {
    @GetMapping("/api/getDeviceStatus")
    BiaoBaseResponse<DeviceStatusInfo> queryBiaoInfo(DeviceStatusInfoRequest request);
}
```

当发起调用的时候，会出现异常，大体意思是`Request method 'POST' not supported`,为什么是POST请求呢？

究其原因是因为feign默认的远程调用使用的是jdk底层的HttpURLConnection，这在feign-core包下的Client接口中的convertAndSend方法可看到:

```java
 if (request.body() != null) {
        if (contentLength != null) {
          connection.setFixedLengthStreamingMode(contentLength);
        } else {
          connection.setChunkedStreamingMode(8196);
        }
        connection.setDoOutput(true);
        OutputStream out = connection.getOutputStream();
        if (gzipEncodedRequest) {
          out = new GZIPOutputStream(out);
        } else if (deflateEncodedRequest) {
          out = new DeflaterOutputStream(out);
        }
        try {
          out.write(request.body());
        } finally {
          try {
            out.close();
          } catch (IOException suppressed) { // NOPMD
          }
        }
      }
```

该段代码片段会判断requestBody是否为空，我们知道GET请求默认是不会有requestBody的，因此该段代码会执行到HttpURLConnection中：

```java
 private synchronized OutputStream getOutputStream0() throws IOException {
        try {
            if (!this.doOutput) {
                throw new ProtocolException("cannot write to a URLConnection if doOutput=false - call setDoOutput(true)");
            } else {
                if (this.method.equals("GET")) {
                    this.method = "POST";
                }
```

最关键的代码片段已显示当请求方式为GET请求，会将该GET请求修改为POST请求，这也就是出现该异常的原因。

那么怎么解决呢?

当然如果你不用POJO的方式去传递出参数当然是可行的，如下：

```java
@FeignClient(name = "BiaoClient", url = "${boss.biao.url}")
public interface BiaoClient {
    @GetMapping("/api/getDeviceStatus")
    BiaoBaseResponse<DeviceStatusInfo> queryBiaoInfo(@RequestParam("sn") String sn,
                                                       @RequestParam("ack") String ack);
}
```

如果想保持POJO作为参数？依然是有方案的。

##### 方案一

> 目前网上搜索到的都是这个方案。

我们只需将feign底层的远程调用由HttpURLConnection修改为其他远程调用方式即可，而且基本不需要修改太多的代码，这里利用apache的HttpClient。

1. `application.properties`加入`feign.httpclien.enabled=true`
2. 加入依赖

```xml
<!-- 使用Apache HttpClient替换Feign原生httpclient -->
<dependency>
  <groupId>com.netflix.feign</groupId>
  <artifactId>feign-httpclient</artifactId>
  <version>8.17.0</version>
</dependency>
```

3. 需要@RequestBody，如下：

```java
@FeignClient(name = "BiaoClient", url = "${boss.biao.url}")
public interface BiaoClient {
    @GetMapping("/api/getDeviceStatus")
    BiaoBaseResponse<DeviceStatusInfo> queryBiaoInfo(@RequestBody DeviceStatusInfoRequest request);
}
```

*额外加一句，在GET方法里，加@RequestBody总感觉别扭。。。*

##### 方案二

这个方案是Spring Cloud OpenFeign官方提供的，我是在看[官方文档](https://cloud.spring.io/spring-cloud-static/spring-cloud-openfeign/2.1.0.RC3/single/spring-cloud-openfeign.html)看到的，于是在github上找查看了一下。

**这个方案更推荐使用**！在github上有这样一个[Issue](https://github.com/spring-cloud/spring-cloud-openfeign/pull/79/files)——`Add support for feign's QueryMap annotation for Object mapping #79`,这个Issue已经是closed，看日期是解决是在2018-12-07号。方法也很简单。保持原来的不用改，不需要添加额外的依赖，加一个注解`@SpringQueryMap `就搞定。

```java
@FeignClient(name = "BiaoClient", url = "${boss.biao.url}")
public interface BiaoClient {
    @GetMapping("/api/getDeviceStatus")
    BiaoBaseResponse<DeviceStatusInfo> queryBiaoInfo(@SpringQueryMap DeviceStatusInfoRequest request);
}
```

下图是解决这个issue改变的代码：
![1](./Xnip2019-01-06_23-53-28.jpg)

注意，要用该注解，需要升级你的Spring Cloud OpenFeign到新的版本（`2.1.0.RC1`以及之后的版本）。
