<template>
 <el-tree
      ref="tree"
      :data="data"
      :props="defaultProps"
      node-key="catId"
      @node-click="nodeClick"
    >
 </el-tree>
</template>

<script>
export default {
  data() {
    return {
      /* 所有需要修改的节点 */
      data: [],
      expandedKey: [],
      defaultProps: {
        children: 'children',
        label: 'name'
      }
    }
  },
  created() {
    this.getCategoryList()
  },
  methods: {
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
    nodeClick(data, node, component) {
      console.log('子组建点击事件 ', data, node, component)
      /* 向父组件传递事件及数据 tree-node-click 事件名 */
      this.$emit('tree-node-click', data, node, component)
    }
  }
}
</script>

<style>

</style>
