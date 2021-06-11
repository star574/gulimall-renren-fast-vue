<template>
  <div v-loading="loading">
    <el-button type="primary" @click="addOne">添加一级菜单</el-button>
    <el-button type="danger" @click="batchDelete">批量删除</el-button>
    <el-input @input="filterChange" v-model="input" class="input" placeholder="请输入内容"></el-input>
    <el-button type="primary">搜索</el-button>
    <el-switch
  class="switchDrop"
  v-model='switchDrop'
  active-color="#13ce66"
  inactive-color="#ff4949"
  :active-text="switchDrop?'允许拖动':'禁止拖动'"
  inactive-text="">
</el-switch>
    <el-button type="success"  class="switchDrop" v-if="updateNodes.length>0" @click="() => batchUpdate()">保存修改</el-button>
    <!-- draggable 可拖拽 -->
    <el-tree
      ref="tree"
      :data="data"
      :props="defaultProps"
      node-key="catId"
      :expand-on-click-node="false"
      show-checkbox=""
      @node-click="handleNodeClick"
      :default-expanded-keys="expandedKey"
      :draggable="switchDrop"
      :allow-drop="allowDrop"
      :filter-node-method="filterNode"
      @node-drop="handleDrop"
    >
      <span class="custom-tree-node" slot-scope="{ node, data }">
        <span>{{ node.label }}</span>
        <span>
          <el-button type="text" size="mini" @click="edit(data)">
            修改
          </el-button>
          <el-button
            v-if="node.childNodes.length == 0"
            type="text"
            size="mini"
            @click="() => remove(node, data)"
          >
            删除
          </el-button>
          <el-button
            v-if="data.catLevel < 3"
            type="text"
            size="mini"
            @click="() => add(data)"
          >
            添加
          </el-button>
          <!-- close-on-click-modal=true 点击外部关闭对话框 -->
          <el-dialog
            title="分类信息"
            :visible.sync="dialogFormVisible"
            :close-on-click-modal="false"
          >
            <el-form :model="category">
              <el-form-item label="分类名称" :label-width="formLabelWidth">
                <el-input v-model="category.name" autocomplete="off"></el-input>
              </el-form-item>
              <el-form-item label="分类排序" :label-width="formLabelWidth">
                <el-input-number
                  v-model="category.sort"
                  :min="0"
                  :max="1000"
                ></el-input-number>
              </el-form-item>
              <el-form-item label="图标" :label-width="formLabelWidth">
                <el-input v-model="category.icon" autocomplete="off"></el-input>
              </el-form-item>
              <el-form-item label="计量单位" :label-width="formLabelWidth">
                <el-input
                  v-model="category.productUnit"
                  autocomplete="off"
                ></el-input>
              </el-form-item>
            </el-form>
            <div slot="footer" class="dialog-footer">
              <el-button @click="dialogFormVisible = false">取 消</el-button>
              <el-button type="primary" @click="append()">确 定</el-button>
            </div>
          </el-dialog>
        </span>
      </span>
    </el-tree>
  </div>
</template>

<script>
export default {
  data() {
    return {
      /* 所有需要修改的节点 */
      updateNodes: [],
      formLabelWidth: '120px',
      dialogFormVisible: false,
      data: [],
      category: {
        sort: '0',
        name: '',
        productUnit: '',
        icon: ''
      },
      expandedKey: [],
      defaultProps: {
        children: 'children',
        label: 'name'
      },
      loading: false,
      /* 切换允许拖动状态 */
      switchDrop: false,
      /* 搜索 */
      input: '',
      /* 默认展开节点 */
      defaultExpand: false
    }
  },
  created() {
    this.getCategoryList()
  },
  watch: {},
  methods: {
    filterNode(value, data) {
      if (!value) return true
      return data.name.indexOf(value) !== -1
    },
    /* 当input框改变时执行 */
    filterChange() {
      /* 搜索前端实现 */
      if (this.input !== '') {
        this.$refs.tree.filter(this.input)
      } else {
        this.data = []
        this.getCategoryList()
      }
    },
    /* 批量删除 */
    batchDelete() {
      let keys = this.$refs.tree.getCheckedKeys()
      let nodes = this.$refs.tree.getCheckedNodes()
      if (keys.length === 0) {
        this.$message({
          message: `未选择节点`,
          type: 'warning'
        })
        return
      }
      if (keys.length !== 0) {
        this.$confirm(`确定对[ ${keys.length > 1 ? `${nodes[0].name}... 等 ${keys.length}个分类 进行批量删除` : '进行删除'} ]操作? 删除分类将会连同子分类一起删除`, '提示', {
          confirmButtonText: '确定',
          cancelButtonText: '取消',
          type: 'warning'
        }).then(() => {
          this.$http({
            url: this.$http.adornUrl('/product/category/batchDelete'),
            method: 'post',
            data: this.$http.adornData(keys, false)
          }).then((res) => {
            this.getCategoryList()
            this.$message({
              message: `${res.data.msg}`,
              type: 'success'
            })
          }
        ).catch((data) => { this.$message.error(data.data.msg) })
        })
      }
    },
    /* 批量修改 */
    batchUpdate() {
  /* 批量更新 loading */
      if (this.updateNodes.length > 0) {
        /* 批量获取pid 实现修改后展开功能 */
        let pId = []
        for (let i = 0; i < this.updateNodes.length; i++) {
          if (this.updateNodes[i].parentCid !== undefined) {
            pId.push(this.updateNodes[i].parentCid)
          }
        }
        this.loading = true
        this.$http({
          url: this.$http.adornUrl(`/product/category/batchUpdate`),
          method: 'post',
          data: this.$http.adornData(this.updateNodes, false)
        }).then(() => {
          this.$message({
            message: '操作成功 !',
            type: 'success'
          })
          this.getCategoryList()
          if (pId.length !== 0) {
            this.expandedKey = pId
          }
        }).catch((err) => {
          this.$message({
            message: `操作失败 ! ${err}`,
            type: 'error'
          })
        })
        this.loading = false
      } else {
        this.$message({
          message: `未发生改变 !`,
          type: 'warning'
        })
      }
      this.updateNodes = []
    },
    /* 拖拽成功触发 更改数据 */
    handleDrop(draggingNode, dropNode, dropType, ev) {
      /* 最新父节点ID */
      let pId = 0
      let siblings = []
      if (dropType === 'before' || dropType === 'after') {
        pId = dropNode.parent.data.parentCid === undefined ? 0 : dropNode.parent.data.catId
        siblings = dropNode.parent.childNodes
      } else {
        siblings = dropNode.childNodes
        pId = dropNode.data.catId
      }
      /* 最新顺序 */
      for (let i = 0; i < siblings.length; i++) {
        /* 当前拖拽节点 */
        if (siblings[i].data.catId === draggingNode.data.catId) {
          /* 层级发生变化 当前节点与目标节点等级差 dropType === 'before' || dropType === 'after' 同级 else 下一级 */
          let level = dropNode.data.catLevel - draggingNode.data.catLevel
          level = dropType === 'before' || dropType === 'after' ? level : level + 1
          if (level !== 0) {
            this.changeLevel(siblings[i], level)
            /* 移除最后一个节点(递归后push的当前节点) */
            this.updateNodes.splice(this.updateNodes.length - 1, 1)
          }
          this.updateNodes.push({catId: siblings[i].data.catId, sort: i, parentCid: pId, catLevel: siblings[i].data.catLevel})
        } else {
          this.updateNodes.push({catId: siblings[i].data.catId, sort: i})
        }
      }
      console.log(this.updateNodes)
    },
    /* 修改所有层级 */
    changeLevel(node, level) {
      /* 层级发生变化 */
      console.log('层级发生变化')
      console.log(node.data.catLevel)
      /* 加上层级差 */
      node.data.catLevel = node.data.catLevel + level
      console.log(node.data.catLevel)
      if (node.childNodes.length && node.childNodes.length > 0) {
        for (let i = 0; i < node.childNodes.length; i++) {
          this.changeLevel(node.childNodes[i], level)
        }
      }
      this.updateNodes.push({catId: node.data.catId, catLevel: node.data.catLevel})
    },
    /* 拖拽节点触发 */
    allowDrop(draggingNode, dropNode, type) {
      let max = 0
      max = this.countNode(draggingNode, max)
      /* 同级别可拖动前后位置  节约性能 */
      if (draggingNode.level === dropNode.level) {
        return type === 'prev' || type === 'next'
      }
      /* 当前子节点数量+目标level <=3 可以拖动前后位置 */
      if (type === 'prev' || type === 'next') {
        return max + dropNode.level <= 3
      } else if (type === 'inner') {
        /* 当前子节点数量+目标level <3 可以插入 */
        return max + dropNode.level < 3
      }
    },
    /* 获取子节点数量 */
    countNode(dropNode, max) {
      if (dropNode.childNodes != null && dropNode.childNodes.length > 0) {
        max += 1
        for (let i = 0; i < dropNode.childNodes.length; i++) {
          let countChild = this.countNode(dropNode.childNodes[i], 1)
          if (countChild > max) {
            max = countChild
          }
        }
      }
      return max
    },
    /* 获取树形列表 */
    getCategoryList(info = '') {
      this.loading = true
      this.$http({
        url: this.$http.adornUrl(`/product/category/list/tree/${info}`),
        method: 'get'
      }).then((result) => {
        this.data = result.data.categoryServiceList
        this.loading = false
      }).catch((err) => {
        console.log(err)
      })
    },
    /* 添加一级 */
    addOne() {
      this.category = {}
      this.category.parentCid = 0
      this.category.catLevel = 1
      this.category.sort = 0
      this.dialogFormVisible = true
    },
    /* 添加二级或三级 */
    add(data) {
      this.category = {}
      this.category.parentCid = data.catId
      this.category.catLevel = data.catLevel + 1
      this.category.sort = 0
      this.dialogFormVisible = true
    },
    /* 修改 */
    edit(data) {
      this.$http({
        url: this.$http.adornUrl(`/product/category/info/${data.catId}`),
        method: 'get'
      }).then((res) => {
        this.category = res.data.category
        this.dialogFormVisible = true
      }).catch((err) => {
        this.$message({
          message: `获取是数据失败 ! ${err}`,
          type: 'error'
        })
      })
    },
    handleNodeClick(data) {
      // console.log(data)
    },
    /* 增加/更新 */
    append() {
      let parentId = this.category.parentCid
      let postAddress = !this.category.catId ? 'save' : 'update'
      console.log(postAddress)
      this.$http({
        url: this.$http.adornUrl(`/product/category/${postAddress}`),
        method: 'post',
        data: this.$http.adornData(this.category, false)
      }).then(() => {
        this.$message({
          message: '操作成功 !',
          type: 'success'
        })
        this.getCategoryList()
        if (parentId !== 0) {
          this.expandedKey = [parentId]
        }
      }).catch((err) => {
        this.$message({
          message: `操作失败 ! ${err}`,
          type: 'error'
        })
      })
      this.dialogFormVisible = false
      this.category = {}
    },
    // 删除
    remove(node, data) {
      let ids = [data.catId]
      let parentId = data.parentCid
      this.$confirm(`确定对 [${data.name}]  进行[ ${data.catId ? '删除' : '批量删除'} ]操作?`, '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        this.$http({
          url: this.$http.adornUrl('/product/category/delete'),
          method: 'post',
          data: this.$http.adornData(ids, false)
        }).then(() => {
          this.getCategoryList()
          this.expandedKey = [parentId]
          this.$message({
            message: '删除成功 !',
            type: 'success'
          })
        }
        ).catch((data) => { this.$message.error(data.msg) })
      })
    }
  }
}
</script>


<style>
.switchDrop{
  float: right;
  height: 35px;
  width: 150;
  margin-left: 40px;
  /* background-color: aqua; */
}
.input{
  width: 280px;
  margin-left: 40px;
}
</style>
