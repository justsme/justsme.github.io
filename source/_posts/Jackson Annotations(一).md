---
title: Jackson Annotations(一)
toc: true
date: 2019-04-27 18:36:52
tags: jackson
categories:
---
> 这周看了一篇`Jackson JSON Tutorial`，觉得很不错，自己也写代码运行学习了一下，做个记录。那个网站是个英文网站，文章结尾我附了地址，想看原版英文的同学可以自己进去学习。下面的内容就是记录其中的一些内容。我所用的Jackson版本为2.9.8。内容有点多，分两次记录。这篇主要介绍一些序列化注解和反序列化注解，了解他们的作用。下一篇再介绍Jackson Property Inclusion Annotations和一些更加普遍的注解。

我是直接建了一个`springboot`项目，直接在里面写的测试。项目的pom.xml.

```xml
<parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>2.1.4.RELEASE</version>
        <relativePath/> <!-- lookup parent from repository -->
    </parent>
    <groupId>com.justme</groupId>
    <artifactId>jackson-demo</artifactId>
    <version>0.0.1-SNAPSHOT</version>
    <name>jackson-demo</name>
    <description>Demo project for Spring Boot</description>

    <properties>
        <java.version>1.8</java.version>
    </properties>

    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-validation</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.mybatis.spring.boot</groupId>
            <artifactId>mybatis-spring-boot-starter</artifactId>
            <version>2.0.1</version>
        </dependency>

        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-devtools</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>com.h2database</groupId>
            <artifactId>h2</artifactId>
            <scope>runtime</scope>
        </dependency>
        <dependency>
            <groupId>org.projectlombok</groupId>
            <artifactId>lombok</artifactId>
            <optional>true</optional>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
```

`jackson`的版本：

```bash
[INFO] +- org.springframework.boot:spring-boot-starter-web:jar:2.1.4.RELEASE:compile
[INFO] |  +- org.springframework.boot:spring-boot-starter-json:jar:2.1.4.RELEASE:compile
[INFO] |  |  +- com.fasterxml.jackson.core:jackson-databind:jar:2.9.8:compile
[INFO] |  |  |  +- com.fasterxml.jackson.core:jackson-annotations:jar:2.9.0:compile
[INFO] |  |  |  \- com.fasterxml.jackson.core:jackson-core:jar:2.9.8:compile
[INFO] |  |  +- com.fasterxml.jackson.datatype:jackson-datatype-jdk8:jar:2.9.8:compile
[INFO] |  |  +- com.fasterxml.jackson.datatype:jackson-datatype-jsr310:jar:2.9.8:compile
[INFO] |  |  \- com.fasterxml.jackson.module:jackson-module-parameter-names:jar:2.9.8:compile
```



## 一. Jackson Serialization Annotations

首先我们看一下序列化注视。

### 1.1 `@JsonAnyGetter`

该注解允许我们灵活的将`Map`的字段作为标准的属性，如下例子：

```java
@Getter
@Setter
public class Student {
    private String name;
    private Map<String, String> properties;

    public Student() {
        properties = new HashMap<String, String>();
    }

    @JsonAnyGetter
    public Map<String, String> getProperties() {
        return properties;
    }
    
    public void add(final String key, final String value) {
        properties.put(key, value);
    }
}
```

```java
@Test
    public void testSerializingUsingJsonAnyGetter() throws JsonProcessingException {
        Student student = new Student();
        student.setName("jack");

        student.add("attr1", "val1");
        student.add("attr2", "val2");

        String result = new ObjectMapper().writeValueAsString(student);
        System.out.println(result);
    }
```

输出结果(经过格式化)：

```js
{
    "name":"jack",
    "attr2":"val2",
    "attr1":"val1"
}
```

如果不加`@JsonAnySetter`,结果为：

```js
{
    "name":"jack",
    "properties":{
        "attr2":"val2",
        "attr1":"val1"
    }
}
```

### 1.2 `@JsonGetter`

`@JsonGetter`可替代`@JsonProperty`标记一个方法作为`Getter`方法，如下：

```java
public class MyBean {
    public int id;
    private String name;

    @JsonGetter("name")
    public String getTheName() {
        return name;
    }
    
    public MyBean(final int id, final String name) {
        this.id = id;
        this.name = name;
    }
}
```

```java
@Test
    public void whenSerializingUsingJsonGetter()
            throws IOException {

        MyBean bean = new MyBean(1, "My bean");

        String result = new ObjectMapper().writeValueAsString(bean);
        System.out.println(result);
    }
```

输出结果：

```js
{
    "id":1,
    "name":"My bean"
}
```

### 1.3 `@JsonPropertyOrder`

该注解可以用来指定序列化时属性的顺序，如下：

```java
@JsonPropertyOrder({ "name", "id" })
public class MyBean {

    public int id;
    private String name;

    @JsonGetter("name")
    public String getTheName() {
        return name;
    }
    
    public MyBean(final int id, final String name) {
        this.id = id;
        this.name = name;
    }
}
```

```java
@Test
    public void whenSerializingUsingJsonGetter()
            throws IOException {

        MyBean bean = new MyBean(1, "My bean");

        String result = new ObjectMapper().writeValueAsString(bean);
        System.out.println(result);
    }
```

输出结果：

```js
{
    "name":"My bean",
    "id":1
}
```

### 1.4 `@JsonRawValue`

该注解可以让jackson准确的序列化一个属性。添加该注解的属性或者方法应按原样包含属性的文本字符串值进行序列化，而不引用字符。这对于在JSON中插入已序列化的值或将javascript函数定义从服务器传递到javascript client非常有用。如下，对比一下添加和不添加该注解序列化的情况：

```java
public class RawBean {

    public String name;

    @JsonRawValue
    public String json;

    public RawBean(final String name, final String json) {
        this.name = name;
        this.json = json;
    }
}
```

```java
@Test
    public void whenSerializingUsingJsonRawValue()
            throws JsonProcessingException {

        RawBean bean = new RawBean("My bean", "{\"attr\":false}");

        String result = new ObjectMapper().writeValueAsString(bean);
        System.out.println(result);
    }
```

输出结果：

```js
{
    "name":"My bean",
    "json":{
        "attr":false
    }
}
```

不加注解的情况：

```js
{"name":"My bean","json":"{\"attr\":false}"}
```

### 1.5 `@JsonValue`

用以替代缺省的方法，由该方法来完成json的字符输出。例如，修改上面的`RawBean`,

```java
public class RawBean {

    public String name;

    @JsonRawValue
    public String json;

    public RawBean(final String name, final String json) {
        this.name = name;
        this.json = json;
    }
    
    @JsonValue
    public String json() {
        return "JsonValue";
    }
}
```

输出结果为：

```
"JsonValue"
```

### 1.6 `@JsonRootName`

直接对比一下效果：

```java
@JsonRootName(value = "user")
public class UserWithRoot {
    public int id;
    public String name;
    
    public UserWithRoot(final int id, final String name) {
        this.id = id;
        this.name = name;
    }
}
```

```java
@Test
    public void whenSerializingUsingJsonRootName()
            throws JsonProcessingException {

        final UserWithRoot user = new UserWithRoot(1, "John");
        final ObjectMapper mapper = new ObjectMapper();
        // 这个需要添加，否则@JsonRootName(value = "user")不会起作用
        mapper.enable(SerializationFeature.WRAP_ROOT_VALUE);

        final String result = mapper.writeValueAsString(user);
        System.out.println(result);
    }
```

输出结果：

```js
{
    "user":{
        "id":1,
        "name":"John"
    }
}
```

不添加该注解,且注释掉 // mapper.enable(SerializationFeature.WRAP_ROOT_VALUE);，则输出结果

```js
{
    "id":1,
    "name":"John"
}
```

### 1.7 `@JsonSerialize`

自定义序列化。

```java
@Getter
@Setter
public class Student {
    private String name;

    @JsonSerialize(using = CustomDateSerializer.class)
    private Date birth;
}
```

```java
@Test
    public void whenSerializingUsingJsonSerialize() throws JsonProcessingException, ParseException {
        Student student = new Student();
        student.setName("shi");
        student.setBirth(new Date());

        String result = new ObjectMapper().writeValueAsString(student);
        System.out.println(result);
    }
```

输出结果：

```js
{"name":"shi","birth":"2019-04-27 04:02:06"}
```

不添加该注解：

```js
{"name":"shi","birth":1556351977873}
```

## 二. Jackson Deserialization Annotations

### 2.1 `@JsonCreator`

我们可以使用@JsonCreator注释来调整反序列化中使用的构造函数/工厂,当我们需要反序列化一些与我们需要获得的目标实体不完全匹配的JSON时，它非常有用。

```java
@Getter
@Setter
public class User {

    private String name;
    private Integer age;

    @JsonCreator
    public User(@JsonProperty("username") String name) {
        System.out.println("------>" + name);
        this.name = name;
    }

    @Override
    public String toString() {
        return "User{" +
                "name='" + name + '\'' +
                ", age=" + age +
                '}';
    }
}
```

```java
 @Test
    public void whenDeserializingUsingJsonCreator() throws IOException {
        final String json = "{\"age\":19,\"username\":\"json creater\"}";

        User user = new ObjectMapper().readerFor(User.class)
                .readValue(json);

        System.out.println(user);
    }
```

输出结果：

```
------>json creater=null
User{name='json creater', age=19}
```

从上面可以看出，当json字符串里的key和实体属性不完全匹配时，这种方案很有效。而且可以发现，利用这个注解我们也不必为实体添加无参构造器。

我们稍微改一下实体类，也可以这么用：

```java
@Getter
@Setter
public class User {

    private String name;

    private Integer age;

//    @JsonCreator
//    public User(@JsonProperty("username") String name) {
//        System.out.println("------>" + name);
//        this.name = name;
//    }
    @JsonCreator
    public User(Map map) {
        System.out.println("------>" + map);
    }

    @Override
    public String toString() {
        return "User{" +
                "name='" + name + '\'' +
                ", age=" + age +
                '}';
    }
}
```

输出结果：

```
------>{age=19, username=json creater}
User{name='null', age=null}
```

### 2.2 `@JacksonInject`

 表示属性将从注入中获取其值，而不是从JSON数据中获取.

```java
public class BeanWithInject {
    @JacksonInject
    public int id;
    public String name;

    public BeanWithInject() {

    }

    public BeanWithInject(final int id, final String name) {
        this.id = id;
        this.name = name;
    }
}
```

```java
 @Test
    public void whenDeserializingUsingJsonInject() throws IOException {
        String json = "{\"name\":\"My bean\"}";
        InjectableValues inject = new InjectableValues.Std().addValue(int.class, 1);

        BeanWithInject bean = new ObjectMapper().reader(inject)
                .forType(BeanWithInject.class)
                .readValue(json);
        assertEquals("My bean", bean.name);
        assertEquals(1, bean.id);
    }
```

上面的Test会success。

### 2.3 `@JsonAnySetter`

`@JsonAnySetter`允许我们灵活地使用Map作为标准属性。在反序列化时，JSON中的属性将简单地添加到地图中.

```java
@Getter
@Setter
public class Student {
    private String name;
    private Map<String, String> properties;

    public Student() {
        properties = new HashMap<String, String>();
    }

    @JsonAnyGetter
    public Map<String, String> getProperties() {
        return properties;
    }

    @JsonAnySetter
    public void add(final String key, final String value) {
        properties.put(key, value);
    }

    @Override
    public String toString() {
        return "Student{" +
                "name='" + name + '\'' +
                ", properties=" + properties +
                '}';
    }
}
```

```java
 @Test
    public void whenDeserializingUsingJsonAnySetter() throws IOException {
        String json = "{\"name\":\"My bean\",\"attr2\":\"val2\",\"attr1\":\"val1\"}";

        Student student = new ObjectMapper().readerFor(Student.class)
                .readValue(json);
        System.out.println(student);
    }
```

输出结果：

```java
Student{name='My bean', properties={attr2=val2, attr1=val1}}
```

### 2.4 `@JsonSetter`

`@JsonSetter` 将该方法标记为setter方法。当我们需要读取一些JSON数据但目标实体类与该数据不完全匹配时，这非常有用，因此我们需要调整该过程以使其适合.在下面的示例中，我们将指定方法`setTheName()`作为MyBean实体中name属性的setter ：

```java
public class MyBean {
    public int id;
    private String name;
 
    @JsonSetter("name")
    public void setTheName(String name) {
        this.name = name;
    }
}
```

```java
@Test
public void whenDeserializingUsingJsonSetter()
  throws IOException {
  
    String json = "{\"id\":1,\"name\":\"My bean\"}";
    MyBean bean = new ObjectMapper()
      .readerFor(MyBean.class)
      .readValue(json);
    assertEquals("My bean", bean.getTheName());
}
```

上面的Test会success。

### 2.5 `@JsonDeserialize`

自定义反序列化器。

```java
@Getter
@Setter
public class Student {
    private String name;
    
    @JsonDeserialize(using = CustomDateDeserializer.class)
    private Date birth;

    @Override
    public String toString() {
        return "Student{" +
                "name='" + name + '\'' +
                ", birth=" + birth +
                '}';
    }
}

```

```java
 @Test
    public void whenDeserializingUsingJsonDeserialize_thenCorrect()
            throws IOException {

        String json = "{\"name\": \"shi\", \"birth\": \"2000-01-01 02:30:00\"}";

        Student student = new ObjectMapper()
                .readerFor(Student.class)
                .readValue(json);

        System.out.println(student);
    }
```

输出结果：

```
Student{name='shi', birth=Sat Jan 01 02:30:00 CST 2000}
```

### 2.6 `@JsonAlias`

`@JsonAlias`定义反序列化过程为属性的一个或多个的替代名称.

```java
@Data
public class AliasBean {
    @JsonAlias({ "fName", "f_name" })
    private String firstName;

    private String lastName;
}
```

```java
@Test
    public void whenDeserializingUsingJsonAlias_thenCorrect() throws IOException {
        String json = "{\"fName\": \"John\", \"lastName\": \"Green\"}";
        AliasBean aliasBean = new ObjectMapper().readerFor(AliasBean.class).readValue(json);

        System.out.println(aliasBean);
        assertThat(aliasBean.getFirstName(), is("John"));
    }
```
输出结果：
```
AliasBean(firstName=John, lastName=Green)
```

[参考:Jackson Annotation Examples](<https://www.baeldung.com/jackson-annotations>)
